# Lab 5: Give your data meaning with an ontology

In Lab 4 you built a gold layer. A gold layer knows its columns, but it does not know your business. In this lab you write down what the business means, in a short process document, and use Kenseme to turn that document into an ontology. You bind the ontology to a gold lakehouse, publish it to Fabric, and ask a Fabric data agent questions in the business's own words. The agent has no instructions at all. Everything it knows comes from the ontology.

**Approximate time:** 70 minutes (after the 15-minute ontology talk)

```text
Process document  -->  Kenseme builds the ontology  -->  Bind to the gold lakehouse  -->  Push to Fabric  -->  Fabric data agent
(how the business      (6 concepts, 33 facts,            (49 bindings)                    (ontology + graph)    answers with charts
 sells online)          10 relationships)
```

> **Start here:** Open your **Macula-FabricDemo-Workshop** workspace.

> **Trial capacity?** Parts A to F run on the same workspace as the earlier labs if your Fabric administrator turned on the ontology settings listed in the [README](../../README.md). Parts G and H need a paid Fabric capacity (F2 or higher), because Microsoft does not support data agents on a trial capacity. If that is you, watch your facilitator do Parts G and H.

## Part A: Check your gold lakehouse (about 5 minutes)

Kenseme binds the ontology to the **AdventureWorksGold** lakehouse that you built in Lab 4. Check that it is ready before you start.

1. In your workspace, open the **AdventureWorksGold** lakehouse. In the **Explorer** pane, open the **...** menu for **Tables**, select **Refresh**, and expand the **dbo** schema. Verify that these eight tables exist, with these row counts:

    | Table | What it holds | Rows |
    | --- | --- | --- |
    | `DimCustomer` | Customers | 12,459 |
    | `DimDate` | One row per day | 1,280 |
    | `DimProduct` | Products | 295 |
    | `DimProductCategory` | Product categories and category groups | 37 |
    | `DimSalesChannel` | Sales channels (Online and Reseller) | 2 |
    | `FactSalesOrder` | One row per order | 16,491 |
    | `FactSalesOrderLine` | One row per order line | 33,260 |
    | `FactSalesOrderLineDetail` | One row per order line, flattened | 33,260 |

1. Switch to the **SQL analytics endpoint**, select **New SQL query**, and run the key check from Lab 4. You should still see **17** rows. Kenseme needs these keys.

    ```sql
    SELECT OBJECT_NAME(parent_object_id) AS tbl, name FROM sys.key_constraints
    UNION ALL
    SELECT OBJECT_NAME(parent_object_id), name FROM sys.foreign_keys;
    ```

    > **Missing tables or keys?** Go back to Lab 4 and run the gold notebook and the keys script. Tell your facilitator if you are stuck.

1. Make sure no notebook sessions are still running. Select **Run** > **Stop session** in any open notebook.
1. In your workspace, create a folder for the objects Kenseme will create. Select **New folder** and name it `Kenseme - AW Online Sales`.

## Part B: Connect Kenseme to your workspace (about 10 minutes)

Before the session, your facilitator added your email address to Kenseme and sent you an invitation.

[[PLACEHOLDER B: Add the exact steps to sign in to Kenseme and connect it to your Fabric workspace. Include the Kenseme web address, the organization name, how to accept the invitation, and how to give Kenseme access to your workspace.]]

When this part is done, you can sign in to Kenseme and you can choose your workspace in Part E.

## Part C: Generate the ontology from a document (about 10 minutes)

A business person wrote the process document you use here. It says what a customer is, what a product is, how an order is made of sales lines, and which channel an order comes in through. No data engineer wrote it, and it does not mention any table.

1. In Kenseme, open **Data Context** > **Ontologies** and select **Add Ontology**.
1. Enter these values, then select **Next**:
    - **Name**: `Adventure Works Online Sales` followed by your initials, for example `Adventure Works Online Sales - AB`
    - **Namespace**: `OnlineSales`
    - **Owner**: *your email address*
    - **Description**: `Business meaning of Adventure Works Cycles sales: customers, products and product categories, sales orders and their sales lines, and the sales channels orders come in through. Built from the online sales process document.`

    > **Note:** Add your initials to names in Kenseme so your items do not clash with other people's in the same organization.

1. Select **Generate with an agent**, then **Next**. Keep the default **Base IRI** and select **Open generator**.
1. Turn **Documents** on and upload the process document from this repo: `Labs/Lab5/Assets/adventure-works-online-sales-process.docx`. Leave **Database** off, and leave every other source off.
1. Replace the text in the **Instructions** box with the text in `Labs/Lab5/Assets/generation-instructions.txt`, then select **Start generation**.

    The generation takes about 4 to 5 minutes. Use the time to read the process document and answer these questions:

    1. Which six concepts does the document describe?
    1. What other names does it give for a Customer, and for a Product? (These are the synonyms.)
    1. What does Section 6, "Not in this model", leave out on purpose? Why might that be a good decision?
    1. Every relationship in Section 4 has an inverse, such as `soldTo` and `buyerOf`. Why would an AI agent need both directions?

## Part D: Review and accept the model (about 5 minutes)

1. When the generation finishes, open **Review proposed changes**. You should see about **Classes +6**, **Attributes +33**, and **Relationships +10**.
1. Check the model before you accept it:
    - The keys are: Customer `customerId`, ProductCategory `productCategoryId`, Product `productId`, SalesChannel `salesChannelId`, SalesOrder `salesOrderId`, and Sale `salesOrderNumber` plus `salesOrderLineNumber`.
    - The class is named `SalesOrder`, not `Order`, because ORDER is a reserved word in the graph query language. Money columns are `double`. Ids and counts are integers.
    - There are no extra classes, no parent classes, and no direct Customer to Product link. Clear the tick box on anything the generator added that the document does not list.
1. Accept the changes. You should see **Ontology generated successfully** and **No structural issues found**.

You now have six concepts, 33 facts, and 10 relationships, all written in the business's own words. None of them came from a table.

## Part E: Bind the ontology to your gold lakehouse (about 10 minutes)

Binding connects each business word to a real table or column.

1. Select **More** > **Bind to Lakehouse**.
1. Fill in the environment:
    - **Name**: `Fabric Online Sales` followed by your initials
    - **Description**: `Gold lakehouse AdventureWorksGold in my workshop workspace, for the online sales ontology built from the process document.`
1. For the Fabric ontology, select **Create new** > **Choose location**. Choose your workspace connection and your workspace, then the `Kenseme - AW Online Sales` folder, then **Use this location**. Set the ontology name to `AW_Online_Sales_Ontology`.

    > **Tip:** The workspace drop-down may need a second click before it lists your workspace.

1. Select **Select lakehouse**, choose your workspace, then **AdventureWorksGold**, then **Use this lakehouse**, and select **Create**. This takes about a minute.
1. Select the arrow next to **More**, then **Generate suggestions** > **Generate**. Kenseme reads your lakehouse and matches each concept, fact, and relationship to a table, column, or key. This takes about a minute.
1. Select **Review plan**. You should see **49 ready** and **0 not bindable**. A group may open partly ticked. Expand each group and tick every row, so the button reads **Apply 49 bindings**, then select it.
1. Check the binding map against this table:

    | Class | Table | Key |
    | --- | --- | --- |
    | Customer | `DimCustomer` | `CustomerKey` |
    | ProductCategory | `DimProductCategory` | `ProductCategoryKey` |
    | Product | `DimProduct` | `ProductKey` |
    | SalesChannel | `DimSalesChannel` | `SalesChannelKey` |
    | SalesOrder | `FactSalesOrder` | `SalesOrderKey` |
    | Sale | `FactSalesOrderLineDetail` | `SalesOrderNumber` + `LineNumber` |

    Four properties have a different column name from the business name: `customerEmail` is `EmailAddress`, `productVariant` is `Variant`, `salesOrderLineNumber` is `LineNumber`, and `orderedOn` is `OrderDate`. Kenseme matched them by meaning, not by name. If **Sale** shows no key, set it by hand to `SalesOrderNumber` plus `LineNumber`.

1. Select the arrow next to **More**, then **Validate**. You should see **All bindings are valid**.

    > If validation flags something, that is a useful result. It tells your data team exactly which table and which column to fix.

## Part F: Push to Fabric and load the graph (about 5 minutes)

1. Select the arrow next to **Sync**, then **Push to Fabric**. The preview should show **Conflicts 0**. Select **Execute Push**. This takes about 30 seconds.
1. In Fabric, open your workspace and the `Kenseme - AW Online Sales` folder. It now holds an ontology item named `AW_Online_Sales_Ontology`, a lakehouse item, and a graph item.
1. Open the **graph** item and select **Save** (or **...** > **Schedule** > **Refresh now**). Wait for the banner **Data load completed**.

    > **Watch out:** Do not move on until you see **Data load completed**. Without it, the agent fails with the error "label does not match any node type".

Kenseme published the business model into Fabric as a native ontology and graph, with the same names you saw in the document: Customer, Product, Sale. Not `DimCustomer`, and not `FactSalesOrderLineDetail`.

## Part G: Create a Fabric data agent on the ontology (about 5 minutes)

> **Trial capacity:** Skip to the end of this lab and watch your facilitator do Parts G and H.

1. In the `Kenseme - AW Online Sales` folder, select **New item** > **Data agent**. Name it `AW Online Sales Ontology Agent` and select **Create**.
1. Select **Add data source**, choose `AW_Online_Sales_Ontology`, and select **Add**. **Do not write any instructions.**
1. Open the **Tools** tab, select **Add code interpreter**, and select **Confirm**.
1. Start a **new chat**. Code Interpreter only applies to new chats.

Code Interpreter lets the agent write and run a small Python program when a question needs math, such as a correlation or a forecast. The agent decides when to use it, and it shows you the code it wrote. It only reads your data and cannot change it.

## Part H: Ask questions (about 15 minutes)

Type each question exactly as written. Clear the chat between questions. Each takes 30 to 60 seconds. Open the run steps to see how the agent answered, and for questions 7 to 10 open the Python code.

> **Your numbers depend on your gold lakehouse.** The expected answers below come from the same gold notebook you ran in Lab 4. If your numbers differ, check that the row counts in Part A match. You can also compare with the SQL answers in notebook 03 from Lab 4.

### Act 1: The agent speaks the business's language

| # | Question | What to expect |
| --- | --- | --- |
| 1 | `Show the items the buyer Larry Vazquez purchased as a bar chart of sales amount by product name.` | 11 bars. The tallest is Road-150 Red, 52 at 3,578.27. The accessories are small bars under 50. |

Neither "items" nor "buyer" is a column in the database. They are the synonyms from the process document. Do not add dates to this question.

### Act 2: What happened online in 2021

| # | Question | What to expect |
| --- | --- | --- |
| 2 | `Show total sales amount by sales channel as a pie chart. List the number of orders for each channel below it.` | Online is about 20.9M on 16,459 orders. Reseller is about 0.7M on 32 orders. If the pie shows order counts, say "by sales amount" and ask again. |
| 3 | `Show monthly online sales as a line chart.` | Flat at 0.4M to 0.8M a month, a soft 2020, then a surge to a peak of about 1.8M in November 2021. |
| 4 | `Show online units sold by product category group and month for 2021 as a stacked column chart.` | Bikes only until April. Accessories and clothing appear in May and take off in June. |
| 5 | `Show the number of new customers by month of their first order in 2021 as a line chart.` | About 200 to 330 a month from January to June, then 1,210 in July and about 1,000 to 1,200 a month to December. |
| 6 | `Show the top 10 product categories by units sold online as a column chart.` | Tires and Tubes first at 8,750, then Road Bikes at 6,010. |

### Act 3: Python tests the story and looks ahead

Start each question with "Using Python" so the agent picks up Code Interpreter.

| # | Question | What to expect |
| --- | --- | --- |
| 7 | `Using Python, plot average unit price against total units sold for every product sold online, on log scales, and give me the correlation of the log values.` | 130 products. A correlation of about -0.58 on the log values: cheaper products sell far more units. |
| 8 | `Using Python, draw a heatmap of online units by product category group and month for 2021.` | Bikes are lit all year. Accessories and Clothing are dark until May and bright from June. |
| 9 | `Using Python, compare online sales of mountain, road and touring bikes for 2019, 2020 and 2021, with year-over-year growth, as a chart with whole years on the x-axis.` | Mountain bikes grow about 130% and then 165%. Road bikes grow about 50% and then shrink 13%. Touring starts in 2021. |
| 10 | `Using Python, forecast online sales for January to March 2022 from the monthly history, and chart the forecast with a range.` | About 3M to 4.7M for the quarter, with a shaded band. |

The story the ten charts tell: online sales took off in the second half of 2021, because accessories and clothing launched, which brought in new buyers. Mountain bikes overtook road bikes. The agent found this with no instructions, because the ontology told it what the words mean and how things connect.

## Tips and things to watch for

- **Say "online" in trend questions.** Online sales run from July 2019 to December 2021, and reseller sales run in 2022. Without "online", a monthly chart gets a 2022 tail that looks like a collapse.
- **Name the chart type.** Say "as a line chart" or "as a pie chart" to get the chart you want.
- **Keep chart questions small.** The agent returns up to 200 rows. Do not add "and by product" to a chart question.
- **Use the full product name.** Product names include a size or color, for example `Road-150 Red, 52`.
- **Code Interpreter did not run?** Start a new chat. If it still answers without Python, add this instruction to the agent and start another new chat: `Use a chart for trend and comparison questions. Use code interpreter for correlations, heatmaps, growth rates and forecasts.`
- **Charts only show in the Fabric screen.** Kenseme's chat, the API, Teams, and Foundry get text and tables. Code Interpreter only runs in the Fabric screen.
- **An answer of 0 or empty?** Fabric SQL is case-sensitive. Clear the chat and ask again.
- **A Fabric ontology name cannot be reused** until the old ontology is deleted. To push again, choose a new name such as `AW_Online_Sales_Ontology_2`. If you delete and recreate the agent, add Code Interpreter again and start a new chat.
- **Kenseme sometimes ignores the first click after a page loads.** Click again. Check that a text box is not empty before you press Enter.
- **Leaving a Kenseme page clears its chat.**

## Homework: clean up

You created several items in this lab. Remove them when you finish exploring, so they stop using capacity.

1. Delete the data agent, the graph item, the ontology item, and the lakehouse item in the `Kenseme - AW Online Sales` folder.
1. Delete the `AdventureWorksGold` and `AdventureWorksSilver` lakehouses if you no longer need them.
1. Follow the cleanup steps in the [README](../../README.md) to remove the whole workspace.

## What you learned

An ontology is a shared, written map of your business: what things are, how they relate, and the rules they follow. People and computers then mean the same thing by the same words. You started from a plain business document, not from tables. Kenseme drafted the model, you decided what stayed, and Kenseme bound it to your gold lakehouse and published it to Fabric. A Fabric data agent with no instructions answered ten questions with charts, because it was given meaning, not just data.

The step to take this week: pick one process you have already written down, and the five questions it should answer. You almost certainly have the data. What an agent is missing is the meaning.

**Previous:** [Lab 4: Build the gold layer](../Lab4/04-build-gold-layer.md)

**Back to the workshop:** [README](../../README.md)
