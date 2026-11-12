# Lab 2: Ingest data with a pipeline

In Lab 1 you uploaded files by hand. In real projects, data arrives from other systems and you need to bring it in on a schedule, without clicking. In this lab you build a data pipeline that copies the reseller orders from an external web address straight into a Delta table in your lakehouse. This is the last source of your bronze layer.

**Approximate time:** 30 minutes

> **Start here:** Open your **Macula-FabricDemo-Workshop** workspace and select your **FabricWorkshopDemo** lakehouse.

## About the data

Adventure Works sells through two channels. The web store orders you uploaded in Lab 1 came from individual customers. **Reseller** orders come from business accounts. They live in a separate file with a different shape: numeric customer and product ids, a line total instead of a unit price, and no tax. In Labs 3 and 4 you combine both channels into one model.

## Create a pipeline

A simple way to ingest data is to use a **Copy data** activity in a pipeline. It extracts data from a source and copies it to a destination in the lakehouse.

1. In the left navigation pane, select your workspace name.
1. Select **New item**, search for **Pipeline**, and create a new pipeline named `Ingest Reseller Orders`.
1. In the pipeline editor, select **Copy data** > **Add copy data activity** on the toolbar. A **Copy data** activity is added to the canvas.

### Configure the source

1. Select the **Copy data** activity, then select the **Source** tab in the pane below the canvas.
1. In the **Connection** drop-down, select **Browse all**, then select **HTTP**. In the **Create a connection** form, enter these settings and select **Connect**:
    - **URL**: `https://raw.githubusercontent.com/MicrosoftLearning/dp-data/main/orders.csv`
    - **Connection name**: *Enter a unique name, for example `http-orders-` followed by your initials*
    - **Data gateway**: (none)
    - **Authentication kind**: Anonymous
    - **Privacy level**: None
1. Back on the **Source** tab, configure these settings:
    - **Relative URL**: *Leave blank*
    - **File format**: **DelimitedText**
1. Select the **Settings** button next to the **File format** drop-down. Confirm these settings and select **OK**:
    - **Compression type**: No compression
    - **Column delimiter**: Comma (,)
    - **Row delimiter**: Line feed (\n)
    - **First row as header**: *Selected*
1. Select **Test connection** to verify that the connection works.

> **If the web address is blocked:** Some company networks block GitHub. In that case, skip the pipeline for now: upload `Labs/Lab2/Assets/orders.csv` to a new `Files/orders` folder, open the **...** menu for the file, select **Load to Tables** > **New table**, choose the `dbo` schema, name the table `orders`, make sure the header option is selected, and confirm. Then go to the SQL check at the end of this section.

### Configure the destination

1. Select the **Destination** tab. In the **Connection** drop-down, select **Browse all**.
1. In the **New connection** dialog, find your lakehouse in the *OneLake Catalog* section and select it.
1. Return to the **Destination** tab and configure these settings:
    - **Connection**: *Your new lakehouse connection*
    - **Lakehouse**: *FabricWorkshopDemo*
    - **Root folder**: Tables
    - **Table**: schema `dbo`, table name `orders`
    - **Table action**: Overwrite

    > **Note:** The notebooks in Lab 3 read a table named exactly `dbo.orders`. Use these names.

1. Select the **Mapping** tab, then select **Import schemas**. Leave the default mapping.

### Run the pipeline

1. On the **Home** tab, select **Save** (&#128427;), then select **&#9655; Run**.
1. Watch the **Output** pane under the designer. Use the refresh icon (&#8635;) until the status shows **Succeeded**. The run takes a minute or two.
1. In the left navigation pane, select your lakehouse. In the **Explorer** pane, open the **...** menu for **Tables**, select **Refresh**, expand the **dbo** schema, and select **orders** to preview the data.
1. Check the table with SQL. Switch to the **SQL analytics endpoint**, select **New SQL query**, and run:

    ```sql
    SELECT COUNT(*) AS OrderLines,
           COUNT(DISTINCT SalesOrderID) AS Orders,
           MIN(OrderDate) AS FirstOrder,
           MAX(OrderDate) AS LastOrder
    FROM dbo.orders;
    ```

    You should see **542** order lines, **32** orders, and dates from 2022-06-01 to 2022-12-01.

## Your bronze layer is complete

You now have all the raw data, exactly as it arrived:

| Source | Where it is | What it holds |
| --- | --- | --- |
| Web store orders | `Files/data/sales.csv` and `Files/bronze/2019.csv` to `2021.csv` | Online order lines, 2019 to 2021 |
| Product catalog | `Files/products/products.csv` | 295 products with category and list price |
| Reseller orders | `Tables/dbo/orders` | Reseller order lines, 2022 |

In the next two labs you clean this data into silver tables and then shape it into a gold star schema.

## If you finish early

Run the pipeline a second time and check the count again. It is still 542, because **Table action** is **Overwrite**. A pipeline that gives the same result every time you run it is safe to schedule. Then open the **Schedule** option on the **Home** tab to see how you would run it every night.

## Tips and things to watch for

- **Give your connections a unique name.** Add your initials to the HTTP connection name so it does not clash with other connections in your tenant. If **Test connection** fails, check the URL for a stray space and make sure **Anonymous** is the authentication kind.
- **Column types.** If **Import schemas** shows a column as a string instead of a number, you can leave it. The silver notebook in Lab 3 converts every column to the type it needs.
- **The table is not showing.** Select **Refresh** on **Tables**. The **dbo** schema node must be expanded. If you created the table without the `dbo` schema, delete it and run the pipeline again with the right names.
- **Check that the pipeline finished.** The status must read **Succeeded** before you look for the table.
- **Your lakehouse needs schemas turned on.** The `dbo.` table names depend on it. You selected it during setup.

**Learn more**

- [Copy data activity](https://learn.microsoft.com/fabric/data-factory/copy-data-activity)
- [Data pipelines in Microsoft Fabric](https://learn.microsoft.com/fabric/data-factory/pipeline-overview)
- [Lakehouse schemas](https://learn.microsoft.com/fabric/data-engineering/lakehouse-schemas)

## What you learned

A pipeline can copy data from an external source into OneLake without any code and can be re-run safely. You now have every bronze source in one lakehouse.

**Previous:** [Lab 1: Work with a Fabric lakehouse](../Lab1/01-lakehouse.md)

**Next:** [Lab 3: Explore bronze and build silver](../Lab3/03-explore-bronze-build-silver.md)
