# Macula Microsoft Fabric and Kenseme Workshop

Hands-on labs for **Macula's four-hour Microsoft Fabric workshop on [[PLACEHOLDER: workshop date]]**. In the first two hours you build a medallion architecture in your own Fabric workspace: you land raw files and ingest them with a pipeline (bronze), clean them with Spark (silver), and shape them into a star schema (gold). After a break, you give that gold data business meaning: you use Kenseme to build an ontology, bind it to your gold lakehouse, publish it to Fabric, and ask a Fabric data agent questions in plain English.

Please complete the setup below **before the session**. It takes about 15 minutes.

## Agenda

| Time | Segment |
| --- | --- |
| 9:00 to 9:15 | Welcome, agenda, setup check |
| 9:15 to 9:45 | [Lab 1](Labs/Lab1/01-lakehouse.md): Land raw files in a lakehouse |
| 9:45 to 10:15 | [Lab 2](Labs/Lab2/02-ingest-pipeline.md): Ingest data with a pipeline (bronze complete) |
| 10:15 to 10:45 | [Lab 3](Labs/Lab3/03-explore-bronze-build-silver.md): Explore bronze and build silver |
| 10:45 to 11:15 | [Lab 4](Labs/Lab4/04-build-gold-layer.md): Build the gold layer |
| 11:15 to 11:30 | Break |
| 11:30 to 11:45 | Ontology 101: why AI needs business meaning |
| 11:45 to 1:00 | [Lab 5](Labs/Lab5/05-kenseme-ontology.md): Give your data meaning with an ontology |

## What you need

- A laptop with a modern browser (Microsoft Edge or Google Chrome). You do not need to install any software.
- **A browser profile with only one Fabric account signed in.** If you are signed in to several Microsoft accounts, use an InPrivate or Incognito window, or a separate browser profile, so Fabric does not pick the wrong account.
- **A Microsoft Fabric account with access to a capacity.** Most people sign in with a work or school account. If you do not have a capacity, you can start a free 60-day Fabric trial: https://learn.microsoft.com/fabric/fundamentals/fabric-trial. If you only have a personal email address, Microsoft documents a route that uses a free Azure account: https://learn.microsoft.com/fabric/fundamentals/free-trial-account-personal-email
- **For Labs 1 to 4:** a trial or paid capacity is enough.
- **For Lab 5, parts A to F (ontology):** your Fabric administrator must turn on two tenant settings: **Users can create Fabric items** and **Users can create ontology (preview) items**. The Fabric ontology feature is in preview. See [Ontology tenant settings](https://learn.microsoft.com/fabric/iq/ontology/overview-tenant-settings).
- **For Lab 5, parts G and H (data agent):** a **paid** Fabric capacity (F2 or higher) with the data agent tenant settings turned on, including the cross-geo processing and storing settings for AI. Microsoft states that data agents are not supported on a trial capacity. If you only have a trial capacity, you can still do Labs 1 to 4 and Lab 5 parts A to F, and you will watch the facilitator do parts G and H. See [Data agent tenant settings](https://learn.microsoft.com/fabric/data-science/data-agent-tenant-settings). If you are unsure, ask your Fabric administrator before the session.
- **A Kenseme account.** Send your work email address to [[PLACEHOLDER: Macula contact name and email]] by [[PLACEHOLDER: date]]. You will receive an invitation from Kenseme. Accept it before the session and check that you can sign in. [[PLACEHOLDER: Kenseme web address and sign-in notes]]

## Step 1: Create a workspace

1. Go to https://app.fabric.microsoft.com and sign in with your Fabric credentials.
1. In the left menu, select **Workspaces**.
1. Create a new workspace and name it `Macula-FabricDemo-Workshop` so it is easy to find.
1. Under **Advanced**, choose a licensing mode that includes Fabric capacity: **Trial**, **Premium**, or **Fabric**.
1. When the workspace opens, it should be empty.

## Step 2: Create a lakehouse

1. In the left menu, select **Create**. If **Create** is not pinned, select the ellipsis (**...**) first.
1. Under **Data Engineering**, select **Lakehouse** and name it `FabricWorkshopDemo`.
1. Leave the **Lakehouse schemas** checkbox **selected**. The labs use `dbo.` table names that need it.
1. Wait about a minute for the lakehouse to be created.
1. In the Lakehouse explorer, confirm you see two empty folders: **Tables** and **Files**.

You create two more lakehouses during the labs: `AdventureWorksSilver` in Lab 3 and `AdventureWorksGold` in Lab 4. Type the three lakehouse names exactly, because the notebooks and Kenseme find them by name.

## Step 3: Get the lab files

Several labs upload sample files from this repo, so you need a copy on your laptop. Use either option:

- **Download ZIP:** On this repo's GitHub page, select **Code** > **Download ZIP**, then unzip it.
- **Git:** Run `git clone [[PLACEHOLDER: repository URL]]`

> **Tip:** Use the files from the unzipped folder. Do not right-click a CSV on the GitHub web page and save it, because that saves the web page instead of the data and the upload will fail later.

## Quick check before you arrive

- [ ] I can sign in at https://app.fabric.microsoft.com
- [ ] I have a workspace named `Macula-FabricDemo-Workshop`
- [ ] It contains a lakehouse named `FabricWorkshopDemo` with empty **Tables** and **Files** folders
- [ ] I have the lab files unzipped on my laptop
- [ ] I know whether my capacity is paid (needed for the data agent in Lab 5) or trial
- [ ] I accepted my Kenseme invitation and can sign in

If you get stuck on any step, reply to your registration email before the session and we will help you sort it out.

## The labs

| Lab | Topic | Approx. time | Lab guide | Files you need |
| --- | --- | --- | --- | --- |
| 1 | Land raw files in a lakehouse | 30 min | [01-lakehouse.md](Labs/Lab1/01-lakehouse.md) | `Labs/Lab1/Assets`: `sales.csv`, `products.csv`, and the `bronze` folder |
| 2 | Ingest data with a pipeline | 30 min | [02-ingest-pipeline.md](Labs/Lab2/02-ingest-pipeline.md) | None (data comes from a URL). Backup file: `Labs/Lab2/Assets/orders.csv` |
| 3 | Explore bronze and build silver | 30 min | [03-explore-bronze-build-silver.md](Labs/Lab3/03-explore-bronze-build-silver.md) | `Labs/Lab3/Assets`: notebooks 00 and 01 |
| 4 | Build the gold layer | 30 min | [04-build-gold-layer.md](Labs/Lab4/04-build-gold-layer.md) | `Labs/Lab4/Assets`: notebooks 02 and 03, and `declare_keys_gold.sql` |
| 5 | Give your data meaning with an ontology | 70 min | [05-kenseme-ontology.md](Labs/Lab5/05-kenseme-ontology.md) | `Labs/Lab5/Assets`: process document and generation instructions |

Labs 1 to 4 use the same workspace and build on each other: each lab needs the result of the one before. In Labs 3 and 4 you run the notebooks as they are. You do not need to type any code.

## Tips for the day

- **The first Spark cell is slow.** Starting a Spark session takes a minute or two. Later cells run quickly.
- **Stop your session when you finish a notebook.** Select **Run** > **Stop session**. An idle session holds compute that other people need. If you see `TooManyRequestsForCapacity` (HTTP 430), stop any other sessions, wait a minute, and try again. See [Job concurrency and queueing in Fabric Spark](https://learn.microsoft.com/fabric/data-engineering/spark-job-concurrency-and-queueing).
- **Attach the right lakehouse to every notebook.** In the notebook, select **Add data items** > **From OneLake catalog** and choose the lakehouse the lab names: **AdventureWorksSilver** for notebooks 00 and 01, and **AdventureWorksGold** for notebooks 02 and 03.
- **Refresh the Explorer pane** after a notebook creates a table, and give the SQL analytics endpoint a minute to catch up.
- **Run cells in order.** Do not re-run cells that append or update data unless the lab says to.
- **Use the exact names in the labs.** Table and folder names are case-sensitive in Spark.
- **Ask for help early.**

## After the workshop (homework): clean up

We will not clean up during the session. When you have finished exploring, remove what you created so it stops using capacity.

1. If a notebook is still running, select **Stop session** on the notebook menu to end the Spark session.
1. In the left bar, select your workspace icon to see all of its items.
1. Select **Workspace settings**.
1. In the **General** section, scroll down and select **Remove this workspace**.
1. Select **Delete** to confirm.

## Credits

Labs 1 to 4 are adapted from the Microsoft Learning [mslearn-fabric](https://github.com/MicrosoftLearning/mslearn-fabric) repository and the [dp-data](https://github.com/MicrosoftLearning/dp-data) sample files, both released under the MIT License. The original license is included in [NOTICE-MicrosoftLearning-LICENSE.txt](NOTICE-MicrosoftLearning-LICENSE.txt). Lab 5 uses the Kenseme ontology method and a process document written for this workshop. The Microsoft Learn modules linked from the original labs are a good place to continue after the workshop.
