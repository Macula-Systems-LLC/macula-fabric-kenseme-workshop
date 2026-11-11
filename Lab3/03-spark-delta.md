# Lab 3: Spark and Delta Lake

In this lab you use PySpark in a Fabric notebook to read a folder of raw order files, explore and summarize the data, and save it as a Delta table. Then you change the table and use Delta's history to go back in time. These are the building blocks of the medallion architecture you create in Lab 4.

**Approximate time:** 30 minutes

> **Start here:** Open your **Macula-FabricDemo-Workshop** workspace and select your **MaculaWorkshopDemo** lakehouse.

## Upload the raw order files

You store raw files in a folder named **bronze**. In Lab 4 you use the same folder as the first layer of your medallion architecture.

1. In the **Explorer** pane, open the **...** menu for the **Files** folder, select **New subfolder**, and create a folder named `bronze`.
1. Open the **...** menu for the **bronze** folder, select **Upload** > **Upload files**, and upload the three files in `Labs/Lab3/Assets/orders` from the repo you downloaded: `2019.csv`, `2020.csv`, and `2021.csv`. Hold the Shift key to select all three at once.
1. Select the **bronze** folder and verify that the three files are listed.

    ![Screenshot of CSV files uploaded to the lakehouse.](./Images/02-uploaded-files.png)

## Create a notebook and read the data

1. In your workspace, select **+ New item**, search for **Notebook**, and create a notebook.
1. Rename it to `Spark and Delta` by selecting the **Notebook xxxx** text at the top left.
1. In the **Explorer** pane, select **Add data items** > **From OneLake catalog**, choose your **MaculaWorkshopDemo** lakehouse, and select **Connect**.
1. Replace the contents of the first cell with this code, then select **&#9655; Run cell**:

    ```python
    from pyspark.sql.types import *

    # Describe the columns, because the files have no header row
    orderSchema = StructType([
        StructField("SalesOrderNumber", StringType()),
        StructField("SalesOrderLineNumber", IntegerType()),
        StructField("OrderDate", DateType()),
        StructField("CustomerName", StringType()),
        StructField("Email", StringType()),
        StructField("Item", StringType()),
        StructField("Quantity", IntegerType()),
        StructField("UnitPrice", FloatType()),
        StructField("Tax", FloatType())
        ])

    # Read all three files from the bronze folder into a DataFrame
    df = spark.read.format("csv").option("header", "false").schema(orderSchema).load("Files/bronze/*.csv")

    display(df.limit(10))
    ```

    > **Note:** This is the first Spark code you run, so a Spark session has to start. The first run can take a minute or so. Later cells run quickly.

    > **Watch out:** The files have **no header row**, so the code uses `"header", "false"` and supplies the column names itself. If you let Spark use the first data row as the header, the next cell fails with an `UNRESOLVED_COLUMN` error.

    The output shows the first 10 order lines. A *DataFrame* is a table of rows and columns that Spark processes in parallel across many files.

## Explore the data

1. Select **+ Code** and run this cell to count what you loaded:

    ```python
    print("Order lines:", df.count())
    print("Orders:", df.select("SalesOrderNumber").distinct().count())
    print("Customers:", df.select("CustomerName", "Email").distinct().count())
    ```

    You should see **32,718** order lines, **16,459** orders, and **12,427** customers.

1. Add a cell to look at one customer's orders:

    ```python
    from pyspark.sql.functions import col

    display(
        df.filter(col("CustomerName") == "Christy Zhu")
          .select("SalesOrderNumber", "OrderDate", "Item", "Quantity", "UnitPrice")
          .orderBy("OrderDate", "SalesOrderNumber")
    )
    ```

    The result has 9 rows from 3 orders: SO43701 (2019), SO51315, and SO57783 (2021).

1. Add a cell to summarize orders and sales by year:

    ```python
    from pyspark.sql import functions as F

    yearlySales = df.groupBy(F.year("OrderDate").alias("Year")) \
        .agg(F.countDistinct("SalesOrderNumber").alias("Orders"),
             F.sum(F.col("Quantity") * F.col("UnitPrice")).cast("decimal(12,2)").alias("Sales")) \
        .orderBy("Year")

    display(yearlySales)
    ```

    You should see these results:

    | Year | Orders | Sales |
    | -- | -- | -- |
    | 2019 | 1,201 | 3,863,120.23 |
    | 2020 | 2,733 | 6,372,462.18 |
    | 2021 | 12,525 | 10,692,440.14 |

1. In the output, switch from **Table** to **Chart** to see the same result as a chart. Choose a column or line chart, with **Year** on the x-axis and **Sales** on the y-axis.

## Save the data as a Delta table

Files in a folder are not easy to query or update. A *Delta table* stores the data in Parquet files plus a transaction log, so you get SQL access, updates, deletes, and history.

1. Add a cell and run this code:

    ```python
    df.write.format("delta").mode("overwrite").saveAsTable("dbo.orders_delta")
    ```

1. In the **Explorer** pane, open the **...** menu for **Tables**, select **Refresh**, and verify that **orders_delta** is listed with the Delta (&#9650;) icon.
1. Add a cell and run this SQL to check the table:

    ```sql
    %%sql
    SELECT COUNT(*) AS OrderLines FROM dbo.orders_delta
    ```

    > **Note:** The `%%sql` line must be the first line of the cell. It tells the notebook to run the cell as Spark SQL instead of PySpark.

    The count is 32,718.

## Change the table and go back in time

Every change to a Delta table is recorded as a new *version*. You can read an older version or restore it.

1. Change one row. Add a cell and run it **once**:

    ```sql
    %%sql
    UPDATE dbo.orders_delta SET Tax = 0 WHERE SalesOrderNumber = 'SO43701'
    ```

1. Check the change:

    ```sql
    %%sql
    SELECT SalesOrderNumber, Item, UnitPrice, Tax FROM dbo.orders_delta WHERE SalesOrderNumber = 'SO43701'
    ```

    The `Tax` value is now 0.

1. See the table's history:

    ```sql
    %%sql
    DESCRIBE HISTORY dbo.orders_delta
    ```

    The history lists version 0 (the load) and version 1 (the update), with the time, operation, and user for each.

1. Read the table as it was **before** the update:

    ```sql
    %%sql
    SELECT SalesOrderNumber, Item, UnitPrice, Tax FROM dbo.orders_delta VERSION AS OF 0 WHERE SalesOrderNumber = 'SO43701'
    ```

    The original `Tax` value, 271.9992, is back. The old version was never lost.

1. Undo the change by restoring version 0:

    ```sql
    %%sql
    RESTORE TABLE dbo.orders_delta TO VERSION AS OF 0
    ```

1. Select **Run** > **Stop session** so the notebook releases its compute for the next lab.

## Tips and things to watch for

- **Run the UPDATE once.** Each run is a new transaction. If you run it twice, the history shows an extra version, which is harmless here but worth noticing.
- **Time travel needs the history.** `VACUUM` removes old files after a retention period (7 days by default). After that, old versions can no longer be read. See the Learn link below.
- **Attach the lakehouse.** If you see an error such as *table or view not found* or *Spark SQL queries are only possible in the context of a lakehouse*, the notebook is not connected to your lakehouse. Use **Add data items** > **From OneLake catalog** again.
- **The first cell is slow, the rest are fast.** Starting a Spark session takes time. If it takes more than a couple of minutes or you see `TooManyRequestsForCapacity` (HTTP 430), stop any other notebook sessions and try again.
- **Stop your session when you finish.** An idle session still holds compute that other people in the room need.
- **Files and tables are separate copies.** The CSV files in `bronze` are untouched. The Delta table is a new copy in a better format.

**Learn more**

- [What are Delta tables in Fabric?](https://learn.microsoft.com/fabric/data-engineering/lakehouse-and-delta-tables)
- [Delta table optimization and V-Order](https://learn.microsoft.com/fabric/data-engineering/delta-optimization-and-v-order)
- [How to use notebooks in Fabric](https://learn.microsoft.com/fabric/data-engineering/how-to-use-notebook)

## What you learned

You read raw files with Spark, summarized them, saved them as a Delta table, changed the table, and used Delta's history to read and restore an earlier version. In Lab 4 you chain these steps into bronze, silver, and gold layers.

**Previous:** [Lab 2: Ingest data with a pipeline](../Lab2/02-ingest-pipeline.md)

**Next:** [Lab 4: Build a medallion architecture](../Lab4/04-medallion-architecture.md)
