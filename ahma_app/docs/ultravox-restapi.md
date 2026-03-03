Accounts
GET
Get Account
GET
Get Call Usage
PATCH
Set TTS API keys
GET
Get Account TTS API Keys
Agents
GET
List Agents
POST
Create Agent
GET
Get Agent
PATCH
Update Agent
DEL
Delete Agent
GET
List Agent Calls
POST
Create Agent Call

Scheduled Call Batches
NEW
GET
List Scheduled Call Batches
POST
Create Scheduled Call Batch
GET
Get Scheduled Call Batch
PATCH
Update Scheduled Call Batch
DEL
Delete Scheduled Call Batch
GET
List Scheduled Call Batch Created Calls
GET
List Scheduled Call Batch Scheduled Calls
Calls, Messages, Stages
Calls Overview
GET
List Calls
GET
Get Call
POST
Create Call
DEL
Delete Call
GET
List Call Messages
GET
List Call Tools
GET
Get Call Recording
GET
List Call Stages
GET
Get Call Stage
GET
List Call Stage Messages
GET
List Call Stage Tools
GET
Get Call Stage Message Audio
GET
List Deleted Calls
GET
Get Deleted Call
GET
List Call Events
GET
Get Sip Logs for a call
POST
Send Data Message to Call
Corpora, Query, Sources
Corpus Service (RAG) Overview
GET
List Corpora
POST
Create Corpus
GET
Get Corpus
PATCH
Update Corpus
DEL
Delete Corpus
POST
Query Corpus
GET
List Corpus Sources
POST
Create Corpus Source
GET
Get Corpus Source
PATCH
Update Corpus Source
DEL
Delete Corpus Source
GET
List Corpus Source Documents
GET
Get Corpus Source Document
POST
Create Corpus File Upload
Tools
GET
List Tools
GET
Get Tool
POST
Create Tool
PUT
Update Tool
DEL
Delete Tool
GET
Get Tool History
POST
Test Tool
Voices
GET
List Voices
GET
Get Voice
POST
Create (Clone) Voice
DEL
Delete Voice
PUT
Replace Voice
PATCH
Update Voice
POST
Preview Voice
GET
Get Voice Sample
Webhooks
GET
List Webhooks
GET
Get Webhook
POST
Create Webhook
PUT
Replace Webhook
PATCH
Update Webhook
DEL
Delete Webhook
Telephony
GET
Get Account SIP configuration
PATCH
Update Account SIP configuration
POST
Create SIP Registration
GET
List SIP Registrations
GET
Get SIP Registration
PATCH
Update SIP Registration
DEL
Delete SIP Registration
GET
Get Twilio Configuration for Account
POST
Create Twilio Configuration for Account
PATCH
Update Twilio Configuration for Account
DEL
Delete Twilio Configuration for Account
GET
Get Telnyx Configuration for Account
POST
Create Telnyx Configuration for Account
PATCH
Update Telnyx Configuration for Account
DEL
Delete Telnyx Configuration for Account
GET
Get Plivo Configuration for Account
POST
Create Plivo Configuration for Account
PATCH
Update Plivo Configuration for Account
DEL
Delete Plivo Configuration for Account
PATCH
Set Telephony Credentials
GET
Get Telephony Credentials


Schema
Base Tool Definition
The base definition of a tool that can be used during a call. Exactly one
implementation (http or client) should be set.

​
modelToolName
string
The name of the tool, as presented to the model. Must match ^[a-zA-Z0-9_-]{1,64}$.

​
description
string
The description of the tool.

​
dynamicParameters
object[]
The parameters that the tool accepts.

Show child attributes

​
staticParameters
object[]
The static parameters added when the tool is invoked.

Show child attributes

​
automaticParameters
object[]
Additional parameters that are automatically set by the system when the tool is invoked.

Show child attributes

​
requirements
object
Requirements that must be fulfilled when creating a call for the tool to be used.

Show child attributes

​
timeout
string
The maximum amount of time the tool is allowed for execution. The conversation is frozen
while tools run, so prefer sticking to the default unless you're comfortable with that
consequence. If your tool is too slow for the default and can't be made faster, still try to
keep this timeout as low as possible.

Pattern: ^-?(?:0|[1-9][0-9]{0,11})(?:\.[0-9]{1,9})?s$
​
precomputable
boolean
The tool is guaranteed to be non-mutating, repeatable, and free of side-effects. Such tools
can safely be executed speculatively, reducing their effective latency. However, the fact they
were called may not be reflected in the call history if their result ends up unused.

​
http
object
Details for an HTTP tool.

Show child attributes

​
client
object
Details for a client-implemented tool. Only body parameters are allowed
for client tools.

​
dataConnection
object
Details for a tool implemented via a data connection websocket. Only body
parameters are allowed for data connection tools.

​
defaultReaction
enum<string>
Indicates the default for how the agent should proceed after the tool is invoked.
Can be overridden by the tool implementation via the X-Ultravox-Agent-Reaction
header.

Available options: AGENT_REACTION_UNSPECIFIED, AGENT_REACTION_SPEAKS, AGENT_REACTION_LISTENS, AGENT_REACTION_SPEAKS_ONCE 
​
staticResponse
object
Static response to a tool. When this is used, this response will be returned
without waiting for the tool's response.