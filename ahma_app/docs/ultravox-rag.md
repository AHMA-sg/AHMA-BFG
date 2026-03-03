Overview: RAG
Give you agent access to product documents, KBs, and more.

LLMs have tremendous knowledge about the world, but they don’t have all the up-to-date specifics about your organization, your products, or other relevant information you might want to provide to your AI voice agents.
RAG is a common technique for grounding agents in the relevant information for your use case.
​
Examples of Knowledge Sources
Let’s consider some of the content that might be useful to serve some popular use cases:
Customer Success & Support:
Product Documentation → user guides, FAQs, troubleshooting steps.
Onboarding Materials → getting started guides, best practices, transcripts from training videos.
Customer Acquisition:
Product Information → features, pricing tiers, competitive comparisons.
Sales Scripts → qualification questions, objection handling, industry-specific use cases.
Operations:
Internal Processes → call routing rules, department directories.
Survey Materials → question banks, follow-up questions, rating scales.
​
Adding RAG to Ultravox
As we saw in the Tools overview, tools provide power-ups for your agents. To use RAG with an Ultravox agent, it’s as simple as using the built-in queryCorpus tool and instructing the agent on how to use the tool.
​
Using the Web App
The easiest way to create a new knowledge base (we call them Corpora) is to use the Ultravox web application. You can also use the API.
1
Create a Corpus

Go to RAG in the Ultravox web app.
Click New Source in the top right corner.

Under Collection click on New Collection.
Give it a Name and Description then click Save.
2
Create a Source

Select the Collection you just created.
Add a Name and Description for the new source.
Click Web and then add any URLs to be crawled.
Click Save and then wait a few moments for the pages to be crawled and the content to be ingested.

3
Use the queryCorpus Tool

Give the built-in queryCorpus tool. to your agents and provide the corpusId. For example, if we wanted to create a voice agent to answer questions about Seattle, we could provide the tool like this:
{
  "systemPrompt": "Use the queryCorpus tool to answer questions about Seattle.",
  "selectedTools": [
    {
      "toolName": "queryCorpus", 
      "parameterOverrides": {
        "corpus_id": "<your_corpus_id_here>",
        "max_results": 5
      }
    }
  ]
}
​
Using the API
Ultravox provides the corpus service for RAG.
1
Create a Corpus

Use the Create Corpus endpoint. Give your new corpus a name and (optional) description. This returns a corpusId.
2
Create a Source

Add a website to crawl using Create Corpus Source. Each source is given a unique sourceId. We will crawl the URL(s) and ingest all the content.
3
Query the Corpus

After everything is loaded, try some queries using the Query Corpus endpoint.
4
Use the queryCorpus Tool

Give the built-in queryCorpus tool. to your agents and provide the corpusId. For example, if we wanted to create a voice agent to answer questions about Seattle, we could provide the tool like this:
{
  "systemPrompt": "Use the queryCorpus tool to answer questions about Seattle.",
  "selectedTools": [
    {
      "toolName": "queryCorpus", 
      "parameterOverrides": {
        "corpus_id": "<your_corpus_id_here>",
        "max_results": 5
      }
    }
  ]
}
​
Using External Vector DB
Let’s assume we have already stored our product documentation in a vector database and can search that content at https://foo.bar/lookupProductInfo.
All you need to do is create a custom tool that uses the external API and then give the tool to your agent.
Here’s how we might create a tool for our Ultravox agent to use:
Example: Adding an external RAG tool
{
  "systemPrompt": "You are a helpful assistant. You have a tool called 'lookupProductInfo' that you must use to find answers.",
  "model": "ultravox-v0.7",
  "selectedTools": [
    {
      "temporaryTool": {
        "modelToolName": "lookupProductInfo",
        "description": "Searches official product documentation using semantic similarity to find relevant information. Use this tool to look up specific product features, specifications, limitations, pricing, or support information. The tool returns the most relevant text chunks from the documentation.",
        "dynamicParameters": [
          {
            "name": "query",
            "location": "PARAMETER_LOCATION_BODY",
            "schema": {
              "description": "A specific, focused search query to find relevant product information",
              "type": "string"
            },
            "required": true
          }
        ],
        "http": {
          "baseUrlPattern": "https://foo.bar/lookupProductInfo",
          "httpMethod": "POST"
        }
      }
    }
  ]
}

Using Static Documents
Use text, PDF, Word, and other documents in your corpus.

You can use files as sources for any of your corpora.
Files can be added via the Web App or via the Create Corpus File Upload API.
​
Upload Files via Web App
1
Create New Source

Go to RAG in the Ultravox web application.
Click New Source in the top right corner.
2
Add Details and Files

Select the Collection to which you want to add the content.
(Optionally) Add a Name and Description for the new source.
Select Document and add files.

3
Save

Click Save and wait a few moments for your content to be uploaded and ingested.
​
Upload Files via API
To upload files using the API, follow these steps:
1
Step 1: Request Upload URL

Use the Create Corpus File Upload API
Include the MIME type string in the request body
This returns the URL to use for upload and the unique ID for the document
URLs expire after 5 minutes. Request a new one if it expires before using it
The URL that is returned is tied to the provided MIME type. The same MIME type must be used during upload.
2
Step 2: Upload File

Use the presignedUrl from Step 1 to upload the document
Ensure the MIME type in the upload matches what was specified in Step 1
For example, if we requested an upload URL for a text file (MIME type text/plain):
FILE_PATH="/path/to/your/file"
UPLOAD_URL="https://storage.googleapis.com/fixie-ultravox-prod/..."

curl -X PUT \
  -H "Content-Type: text/plain" \
  --data-binary @"$FILE_PATH" \
  "$UPLOAD_URL"
3
Step 3: Create New Source with Uploaded Document

Use the Create Corpus Source API
Use upload to provide the documentId from Step 1
You can provide an array of Document IDs to bulk create a source.
​
Supported File Types
The following types of static files are currently supported:
File Extension	Type of File	MIME Type
doc	Microsoft Word Document	application/msword
docx	Microsoft Word Open XML Document	application/vnd.openxmlformats-officedocument.wordprocessingml.document
txt	Plain Text Document	text/plain
md	Markdown Document	text/markdown
ppt	Microsoft PowerPoint Presentation	application/vnd.ms-powerpoint
pptx	Microsoft PowerPoint Open XML Presentation	application/vnd.openxmlformats-officedocument.presentationml.presentation
pdf	Portable Document Format	application/pdf
​
Limits
See the Overall Limits section for details on limits for the number of sources, file sizes, and more


imits and Configuration
​
Overall Limits
The system has the following limits:
20 sources (max) per corpus
200 documents (max) per source
10MB (max) document size for file uploads
​
Account Limits
Default limit is 2 corpora per account
Paid plans have higher limits on corpora
​
Document Management
Documents can be viewed but not edited directly
To update documents, create a new source
Supported document types:
Text files (including Markdown)
PDFs
Word documents
EPUB files
PowerPoint presentations
Note: If there are additional content types you need, please let us know.
​
Source Management
PATCH requests on a source triggers a refresh/recrawl while maintaining the ID and created timestamp
The corpus is still queryable during a recrawl but might return inconsistent (i.e. outdated) resources until the recrawl is finished
Provided urls via startUrls will trigger crawling on anything in the same domain (subdomains must be specified separately)
​
Deletion Behavior
Deleting a corpus cascades to remove all associated:
Sources
Documents
Chunks
Vectors
Deleted corpora cannot be queried
Deleting a source cascades to remove all associated documents, chunks, and vectors



