# Lab 4: Build a medallion architecture

In this lab you build a medallion architecture in your lakehouse. You keep the raw files as the **bronze** layer, clean them into a **silver** Delta table, and model them into a star schema of **gold** Delta tables: a date dimension, a customer dimension, a product dimension, and a sales fact table. Gold is the business-ready data that reports, semantic models, and AI agents are built on.

**Approximate time:** 30 minutes

> **Start here:** Open your **Macula-FabricDemo-Workshop** workspace and select your **MaculaWorkshopDemo** lakehouse.

```text
Bronze (raw files)  -->  Silver (cleaned Delta table)  -->  Gold (star schema Delta tables)
Files/bronze/*.csv       dbo.sales_silver                    dbo.dimdate_gold, dbo.dimcustomer_gold,
                                                             dbo.dimproduct_gold, dbo.factsales_gold
```

## Check the bronze layer

Bronze holds the data exactly as it arrived, with no changes. You uploaded these files in Lab 3.

1. In the **Explorer** pane, expand **Files** and select the **bronze** folder. Verify that `2019.csv`, `2020.csv`, and `2021.csv` are listed.

    ![Screenshot of the uploaded files in the bronze folder.](./Images/bronze-files.png)

    > **If you skipped Lab 3:** Create a folder named `bronze` under **Files** and upload the three files from `Labs/Lab3/Assets/orders` into it.

## Create the silver layer

You use a notebook to clean the bronze data and load it into a Delta table. Silver is where data becomes consistent and trustworthy.

1. In your workspace, select **+ New item**, search for **Notebook**, and create a notebook.
1. Rename it to `Transform data for Silver` by selecting the **Notebook xxxx** text at the top left.

    ![Screenshot of a new notebook named Transform data for Silver.](./Images/sales-notebook-rename.png)

1. In the **Explorer** pane, select **Add data items** > **From OneLake catalog**, choose your **MaculaWorkshopDemo** lakehouse, and select **Connect**.
1. Replace the contents of the first cell with this code, then select **&#9655; Run cell**:

    ```python
    from pyspark.sql.types import *
    from pyspark.sql.functions import when, lit, col, current_timestamp, input_file_name

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

    # Read all files from the bronze folder
    df = spark.read.format("csv").option("header", "false").schema(orderSchema).load("Files/bronze/*.csv")

    # Add columns that track where each row came from and when it was loaded
    df = df.withColumn("FileName", input_file_name()) \
        .withColumn("IsFlagged", when(col("OrderDate") < '2019-08-01', True).otherwise(False)) \
        .withColumn("CreatedTS", current_timestamp()).withColumn("ModifiedTS", current_timestamp())

    # Replace a missing customer name with "Unknown"
    df = df.withColumn("CustomerName", when((col("CustomerName").isNull() | (col("CustomerName") == "")), lit("Unknown")).otherwise(col("CustomerName")))

    display(df.limit(10))
    ```

    The cell reads the raw files, adds audit columns (source file, a flag for early orders, created and modified times), and cleans empty customer names. These small steps are what turn bronze into silver.

1. Add a new cell, paste this code, and run it. It creates the silver table and then *merges* the data into it:

    ```python
    from delta.tables import *

    # Create the silver Delta table if it does not exist yet
    DeltaTable.createIfNotExists(spark) \
        .tableName("dbo.sales_silver") \
        .addColumn("SalesOrderNumber", StringType()) \
        .addColumn("SalesOrderLineNumber", IntegerType()) \
        .addColumn("OrderDate", DateType()) \
        .addColumn("CustomerName", StringType()) \
        .addColumn("Email", StringType()) \
        .addColumn("Item", StringType()) \
        .addColumn("Quantity", IntegerType()) \
        .addColumn("UnitPrice", FloatType()) \
        .addColumn("Tax", FloatType()) \
        .addColumn("FileName", StringType()) \
        .addColumn("IsFlagged", BooleanType()) \
        .addColumn("CreatedTS", DateType()) \
        .addColumn("ModifiedTS", DateType()) \
        .execute()

    # Upsert: insert new rows, leave rows that already exist as they are
    deltaTable = DeltaTable.forPath(spark, 'Tables/dbo/sales_silver')

    deltaTable.alias('silver') \
      .merge(
        df.alias('updates'),
        'silver.SalesOrderNumber = updates.SalesOrderNumber and silver.OrderDate = updates.OrderDate and silver.CustomerName = updates.CustomerName and silver.Item = updates.Item'
      ) \
       .whenMatchedUpdate(set =
        {

        }
      ) \
     .whenNotMatchedInsert(values =
        {
          "SalesOrderNumber": "updates.SalesOrderNumber",
          "SalesOrderLineNumber": "updates.SalesOrderLineNumber",
          "OrderDate": "updates.OrderDate",
          "CustomerName": "updates.CustomerName",
          "Email": "updates.Email",
          "Item": "updates.Item",
          "Quantity": "updates.Quantity",
          "UnitPrice": "updates.UnitPrice",
          "Tax": "updates.Tax",
          "FileName": "updates.FileName",
          "IsFlagged": "updates.IsFlagged",
          "CreatedTS": "updates.CreatedTS",
          "ModifiedTS": "updates.ModifiedTS"
        }
      ) \
      .execute()
    ```

    A *merge* updates matching rows and inserts new ones. Because of it, you can run this notebook again as new files arrive without creating duplicates.

1. In the **Explorer** pane, open the **...** menu for **Tables**, select **Refresh**, and verify that the **sales_silver** table is listed.
1. Select **Run** > **Stop session** so the notebook releases its compute.

### Check silver with SQL

1. Go back to your lakehouse. At the top right, switch from **Lakehouse** to **SQL analytics endpoint**.

    ![Screenshot of the SQL analytics endpoint in a lakehouse.](./Images/sql-endpoint-item.png)

1. Select **New SQL query**, paste this query, and select **Run**:

    ```sql
    SELECT YEAR(OrderDate) AS Year
        , CAST (SUM(Quantity * (UnitPrice + Tax)) AS DECIMAL(12, 2)) AS TotalSales
    FROM dbo.sales_silver
    GROUP BY YEAR(OrderDate)
    ORDER BY YEAR(OrderDate)
    ```

    ![Screenshot of the results of a SQL query in a lakehouse.](./Images/total-sales-sql.png)

    > **Note:** If the table is not there yet, wait a minute and refresh. The SQL analytics endpoint syncs from the lakehouse in the background.

## Create the gold layer

Now you model the silver data into a star schema: one fact table of sales and three dimension tables that describe them. Gold is what business users and reports read.

1. Switch back to the **Lakehouse** view. In your workspace, create a new notebook named `Transform data for Gold`, and add your **MaculaWorkshopDemo** lakehouse as before (**Add data items** > **From OneLake catalog**).
1. Replace the contents of the first cell with this code and run it. It loads the silver table:

    ```python
    from pyspark.sql.types import *
    from pyspark.sql.functions import col, dayofmonth, month, year, date_format, split, when, lit, coalesce, max, monotonically_increasing_id
    from delta.tables import *

    # Load the silver table as the starting point for the gold layer
    df = spark.read.table("dbo.sales_silver")
    ```

    > **Note:** If you get a `[TooManyRequestsForCapacity]` error, make sure you stopped the session in the silver notebook.

### Date dimension

1. Add a new cell, paste this code, and run it:

    ```python
    # Create the date dimension table
    DeltaTable.createIfNotExists(spark) \
        .tableName("dbo.dimdate_gold") \
        .addColumn("OrderDate", DateType()) \
        .addColumn("Day", IntegerType()) \
        .addColumn("Month", IntegerType()) \
        .addColumn("Year", IntegerType()) \
        .addColumn("mmmyyyy", StringType()) \
        .addColumn("yyyymm", StringType()) \
        .execute()

    # One row for each distinct order date
    dfdimDate_gold = df.dropDuplicates(["OrderDate"]).select(col("OrderDate"), \
            dayofmonth("OrderDate").alias("Day"), \
            month("OrderDate").alias("Month"), \
            year("OrderDate").alias("Year"), \
            date_format(col("OrderDate"), "MMM-yyyy").alias("mmmyyyy"), \
            date_format(col("OrderDate"), "yyyyMM").alias("yyyymm"), \
        ).orderBy("OrderDate")

    display(dfdimDate_gold.limit(10))

    # Insert dates that are not in the table yet
    deltaTable = DeltaTable.forPath(spark, 'Tables/dbo/dimdate_gold')

    deltaTable.alias('gold') \
      .merge(
        dfdimDate_gold.alias('updates'),
        'gold.OrderDate = updates.OrderDate'
      ) \
       .whenMatchedUpdate(set =
        {

        }
      ) \
     .whenNotMatchedInsert(values =
        {
          "OrderDate": "updates.OrderDate",
          "Day": "updates.Day",
          "Month": "updates.Month",
          "Year": "updates.Year",
          "mmmyyyy": "updates.mmmyyyy",
          "yyyymm": "updates.yyyymm"
        }
      ) \
      .execute()

    ```

### Customer dimension

1. Add a new cell, paste this code, and run it. It builds one row per customer, splits the name into first and last, and gives every customer a new `CustomerID`:

    ```python
    # Create the customer dimension table
    DeltaTable.createIfNotExists(spark) \
        .tableName("dbo.dimcustomer_gold") \
        .addColumn("CustomerName", StringType()) \
        .addColumn("Email",  StringType()) \
        .addColumn("First", StringType()) \
        .addColumn("Last", StringType()) \
        .addColumn("CustomerID", LongType()) \
        .execute()

    # One row for each distinct customer, with first and last name
    dfdimCustomer_silver = df.dropDuplicates(["CustomerName","Email"]).select(col("CustomerName"),col("Email")) \
        .withColumn("First",split(col("CustomerName"), " ").getItem(0)) \
        .withColumn("Last",split(col("CustomerName"), " ").getItem(1))

    # Keep only customers that are not in the gold table yet, and give them new IDs
    dfdimCustomer_temp = spark.read.table("dbo.dimcustomer_gold")
    MAXCustomerID = dfdimCustomer_temp.select(coalesce(max(col("CustomerID")),lit(0)).alias("MAXCustomerID")).first()[0]

    dfdimCustomer_gold = dfdimCustomer_silver.join(dfdimCustomer_temp,(dfdimCustomer_silver.CustomerName == dfdimCustomer_temp.CustomerName) & (dfdimCustomer_silver.Email == dfdimCustomer_temp.Email), "left_anti")
    dfdimCustomer_gold = dfdimCustomer_gold.withColumn("CustomerID",monotonically_increasing_id() + MAXCustomerID + 1)

    display(dfdimCustomer_gold.limit(10))

    # Insert the new customers
    deltaTable = DeltaTable.forPath(spark, 'Tables/dbo/dimcustomer_gold')

    deltaTable.alias('gold') \
      .merge(
        dfdimCustomer_gold.alias('updates'),
        'gold.CustomerName = updates.CustomerName AND gold.Email = updates.Email'
      ) \
       .whenMatchedUpdate(set =
        {

        }
      ) \
     .whenNotMatchedInsert(values =
        {
          "CustomerName": "updates.CustomerName",
          "Email": "updates.Email",
          "First": "updates.First",
          "Last": "updates.Last",
          "CustomerID": "updates.CustomerID"
        }
      ) \
      .execute()

    ```

### Product dimension

1. Add a new cell, paste this code, and run it. It builds one row per product and splits the item text into a name and a size or other detail:

    ```python
    # Create the product dimension table
    DeltaTable.createIfNotExists(spark) \
        .tableName("dbo.dimproduct_gold") \
        .addColumn("ItemName", StringType()) \
        .addColumn("ItemID", LongType()) \
        .addColumn("ItemInfo", StringType()) \
        .execute()

    # One row for each distinct item
    dfdimProduct_silver = df.dropDuplicates(["Item"]).select(col("Item")) \
        .withColumn("ItemName",split(col("Item"), ", ").getItem(0)) \
        .withColumn("ItemInfo",when((split(col("Item"), ", ").getItem(1).isNull() | (split(col("Item"), ", ").getItem(1)=="")),lit("")).otherwise(split(col("Item"), ", ").getItem(1)))

    # Keep only products that are not in the gold table yet, and give them new IDs
    dfdimProduct_temp = spark.read.table("dbo.dimproduct_gold")
    MAXProductID = dfdimProduct_temp.select(coalesce(max(col("ItemID")),lit(0)).alias("MAXItemID")).first()[0]

    dfdimProduct_gold = dfdimProduct_silver.join(dfdimProduct_temp,(dfdimProduct_silver.ItemName == dfdimProduct_temp.ItemName) & (dfdimProduct_silver.ItemInfo == dfdimProduct_temp.ItemInfo), "left_anti")
    dfdimProduct_gold = dfdimProduct_gold.withColumn("ItemID",monotonically_increasing_id() + MAXProductID + 1)

    display(dfdimProduct_gold.limit(10))

    # Insert the new products
    deltaTable = DeltaTable.forPath(spark, 'Tables/dbo/dimproduct_gold')

    deltaTable.alias('gold') \
      .merge(
            dfdimProduct_gold.alias('updates'),
            'gold.ItemName = updates.ItemName AND gold.ItemInfo = updates.ItemInfo'
            ) \
            .whenMatchedUpdate(set =
            {

            }
            ) \
            .whenNotMatchedInsert(values =
             {
              "ItemName": "updates.ItemName",
              "ItemInfo": "updates.ItemInfo",
              "ItemID": "updates.ItemID"
              }
              ) \
              .execute()

    ```

### Fact table

1. Add a new cell, paste this code, and run it. It joins the sales lines to the customer and product dimensions so the fact table holds only IDs and measures:

    ```python
    # Create the fact table
    DeltaTable.createIfNotExists(spark) \
        .tableName("dbo.factsales_gold") \
        .addColumn("CustomerID", LongType()) \
        .addColumn("ItemID", LongType()) \
        .addColumn("OrderDate", DateType()) \
        .addColumn("Quantity", IntegerType()) \
        .addColumn("UnitPrice", FloatType()) \
        .addColumn("Tax", FloatType()) \
        .execute()

    # Look up the IDs from the dimensions
    dfdimCustomer_temp = spark.read.table("dbo.dimcustomer_gold")
    dfdimProduct_temp = spark.read.table("dbo.dimproduct_gold")

    df = df.withColumn("ItemName",split(col("Item"), ", ").getItem(0)) \
        .withColumn("ItemInfo",when((split(col("Item"), ", ").getItem(1).isNull() | (split(col("Item"), ", ").getItem(1)=="")),lit("")).otherwise(split(col("Item"), ", ").getItem(1)))

    dffactSales_gold = df.alias("df1").join(dfdimCustomer_temp.alias("df2"),(df.CustomerName == dfdimCustomer_temp.CustomerName) & (df.Email == dfdimCustomer_temp.Email), "left") \
            .join(dfdimProduct_temp.alias("df3"),(df.ItemName == dfdimProduct_temp.ItemName) & (df.ItemInfo == dfdimProduct_temp.ItemInfo), "left") \
        .select(col("df2.CustomerID") \
            , col("df3.ItemID") \
            , col("df1.OrderDate") \
            , col("df1.Quantity") \
            , col("df1.UnitPrice") \
            , col("df1.Tax") \
        ).orderBy(col("df1.OrderDate"), col("df2.CustomerID"), col("df3.ItemID"))

    display(dffactSales_gold.limit(10))

    # Insert the new sales rows
    deltaTable = DeltaTable.forPath(spark, 'Tables/dbo/factsales_gold')

    deltaTable.alias('gold') \
      .merge(
        dffactSales_gold.alias('updates'),
        'gold.OrderDate = updates.OrderDate AND gold.CustomerID = updates.CustomerID AND gold.ItemID = updates.ItemID'
      ) \
       .whenMatchedUpdate(set =
        {

        }
      ) \
     .whenNotMatchedInsert(values =
        {
          "CustomerID": "updates.CustomerID",
          "ItemID": "updates.ItemID",
          "OrderDate": "updates.OrderDate",
          "Quantity": "updates.Quantity",
          "UnitPrice": "updates.UnitPrice",
          "Tax": "updates.Tax"
        }
      ) \
      .execute()

    ```

    If the preview shows `null` in `CustomerID` or `ItemID`, the customer or product cell was not run first. Run those cells, then run this one again.

### Check your work

1. Add a last cell, run it, and compare the counts to the table below:

    ```python
    for t in ["sales_silver", "dimdate_gold", "dimcustomer_gold", "dimproduct_gold", "factsales_gold"]:
        print(t, spark.read.table(f"dbo.{t}").count())
    ```

    | Table | Expected rows |
    | --- | --- |
    | `sales_silver` | 32,718 |
    | `dimdate_gold` | 914 |
    | `dimcustomer_gold` | 12,427 |
    | `dimproduct_gold` | 130 |
    | `factsales_gold` | 32,718 |

1. Open the **...** menu for **Tables** in the **Explorer** pane, select **Refresh**, and confirm that the five tables exist.
1. Select **Run** > **Stop session**.

You now have a medallion architecture: raw files in bronze, a cleaned Delta table in silver, and a star schema in gold.

## If you fall behind

Two ready-made notebooks contain the same cells as this lab: `Labs/Lab4/Assets/Transform-data-for-Silver.ipynb` and `Labs/Lab4/Assets/Transform-data-for-Gold.ipynb`. In your workspace, select **Import** > **Notebook** > **From this computer**, upload them, open each one, add your **MaculaWorkshopDemo** lakehouse (**Add data items** > **From OneLake catalog**), and select **Run all**. Run the silver notebook first.

## Homework: create a semantic model

Open your lakehouse, select **New semantic model** on the ribbon, name it `Sales_Gold`, and select the four gold tables. You can then define relationships and measures, and build a report. This needs a paid capacity with Power BI capabilities or a Power BI Pro or Premium Per User license.

## Tips and things to watch for

- **Stop the silver session before starting the gold notebook.** Two notebooks with active sessions use twice the compute. If the first cell of the gold notebook fails with `TooManyRequestsForCapacity`, go back to the first notebook and select **Run** > **Stop session**.
- **Run the cells in order, and do not skip the dimensions.** The fact table is built with left joins to the customer and product dimensions.
- **Do not worry about re-running.** Every load uses a merge, so running a notebook again does not duplicate rows. This is the main point of the pattern.
- **Table names use lowercase with `_gold` and `_silver`.** Keep them exactly, because later cells refer to them.
- **Temporary results disappear with the session.** DataFrames such as `df` live only while the session runs. If the session ends, run the notebook from the top.
- **If a count is higher than expected,** you probably uploaded the files into `bronze` twice, or ran a cell that appends outside the merge. Delete the tables and run the notebooks again from the top.
- **The gold tables here are not the ones Lab 5 uses.** Lab 5 creates a second lakehouse with its own gold tables, so the ontology is built on a model designed for it.

**Learn more**

- [Implement medallion lakehouse architecture in Fabric](https://learn.microsoft.com/fabric/onelake/onelake-medallion-lakehouse-architecture)
- [What are Delta tables in Fabric?](https://learn.microsoft.com/fabric/data-engineering/lakehouse-and-delta-tables)
- [SQL analytics endpoint metadata sync](https://learn.microsoft.com/fabric/data-engineering/sql-analytics-endpoint-metadata-sync)

## What you learned

You moved data through the bronze, silver, and gold layers of a medallion architecture using PySpark and Delta Lake. You cleaned the raw data, upserted it into a silver table, and modeled it into a star schema with a fact table and three dimensions. Each step uses a merge, so you can rerun the notebooks as new data arrives without creating duplicates.

After the break, you give this data meaning. In Lab 5 you build a gold layer for an ontology and use Kenseme to connect business concepts to it.

**Previous:** [Lab 3: Spark and Delta Lake](../Lab3/03-spark-delta.md)

**Next:** [Lab 5: Give your data meaning with an ontology](../Lab5/05-kenseme-ontology.md)
