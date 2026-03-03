Overview: Tools
Give your agents additional capabilities while maintaining a natural conversation flow.

Tools in Ultravox (also known as function calling) are a powerful way to extend your agents' capabilities by connecting them to external services and systems. At their core, tools are simply functions that agents can invoke to perform specific actions or retrieve information.

Ultravox includes built-in tools and you can create custom tools.

Here are some of the things you can do with tools:
Communicate with the Outside world
Lookup the weather, get movie times, create calendar events, or send emails.
Order Lookup
Lookup orders, backordered items, or provide shipment updates.
Knowledge Base
Consult product and support documentation for contextual support.
Create Support Case
Open tailored support cases for human follow-up.
Transfer Call
Hand-off or escalate calls to human support agents.
End Call
End calls due to user inactivity or after successful resolution.

Any functionality you can encapsulate in a function can be exposed to your agents as a tool. Addtionally, unlike other LLM APIs where you have to handle tool calls yourself, Ultravox actually executes your tools during live conversations, enabling real-time interactions with external systems, databases, and APIs.
​
Types of Tools
​
Built-in Tools
Ultravox provides several ready-to-use tools for common functionality:
queryCorpus: Retrieve information from knowledge bases.
playDtmfSounds: Play dial tones for telephony applications.
leaveVoicemail: Leaves voicemail message and ends the call.
hangUp: End calls programmatically.
Learn more about Built-in Tools →
​
Custom Tools
Create your own tools to integrate with any external system or API. Custom tools can:
Send emails or notifications
Look up customer information
Process payments
Update databases
Integrate with third-party services

Built-in Tools
Ready-to-use tools for common functionality in voice applications.

Ultravox Realtime includes several built-in tools that provide common functionality out of the box. These tools are publicly available and work exactly like custom tools you create yourself.
​
Available Built-in Tools
Tool Name	Description
queryCorpus	Retrieves relevant information from an existing corpus (knowledge base). See Query Corpus API for details.
leaveVoicemail	Leaves a voicemail and ends the call. Intended to be used with outbound phone calls.
hangUp	Terminates the call programmatically. Useful for ending conversations gracefully.
playDtmfSounds	Plays dual-tone multi-frequency (dialpad) tones. See DTMF documentation for sending and receiving tones.
coldTransfer	Transfers the current call to a human operator. See Call Transfers for more details.
More information about these can be found below in Tool Details →
Built-in tools use the same definition structure as custom tools. You can view their complete specifications using the List Tools API.
​
Using Built-in Tools
Using built-in tools is the same as using any other custom durable tool that you have created except for one difference: you can override built-in tools by using the same name.
For example, if you created a durable tool named “hangUp” and then provide that tool by name (i.e. not by the toolId), then your tool would be used instead of the built-in hangUp tool.
Add built-in tools when creating agents, calls, or call stages:
​
Using Tool Names
// Add the hangUp tool by name
{
  "systemPrompt": "You are a helpful assistant. When the conversation naturally concludes, use the 'hangUp' tool to end the call.",
  "selectedTools": [
    { "toolName": "hangUp" }
  ]
}
​
Using Tool IDs
If you have multiple tools with the same name, you can use the unique toolId instead. Agents will see the modelToolName.
// Add the hangUp tool by ID (more explicit)
{
  "systemPrompt": "You are a helpful assistant. When the conversation naturally concludes, use the 'hangUp' tool to end the call.",
  "selectedTools": [
    { "toolId": "56294126-5a7d-4948-b67d-3b7e13d55ea7" }
  ]
}
​
Viewing Available Tools
Use the List Tools API to see all available tools, including built-ins:
curl -X GET "https://api.ultravox.ai/api/tools" \
  -H "X-API-Key: your-api-key"
The List Tools API returns both built-in tools and any custom tools you’ve created, making it easy to see all tools available in your account.
​
Tool Parameters
Tools can use and pass parameters (i.e. send variables to the underlying API). The parameters for each built-in tool are explained below.
See Tool Parameters → for details about the different types of parameters used by tools.
Tool Parameters
Tools can use and pass parameters (i.e. send variables to the underlying API). The parameters for each built-in tool are explained below.
See Tool Parameters → to learn about the different types of parameters used by tools.
​
Built-in Tool Details
​
queryCorpus
Searches through a knowledge base (corpus) to find relevant information (AKA RAG).
Requires the ID of the corpus (corpus_id) to be used for all queries and a dynamic query parameter is used for each query. Optionally, you can restrict the number of results that are returned to the agent (via max_results) along with a minimum semantic similarity score (minimum_score).
Example Usage:
Using queryCorpus Tool

// Basic usage
{
  "selectedTools": [
    {
      "toolName": "queryCorpus",
      "parameterOverrides": {
        "corpus_id": "your-corpus-id-here"
      }
    }
  ]
}

// Require semantic similarity of 0.8 or higher
{
  "selectedTools": [
    {
      "toolName": "queryCorpus",
      "parameterOverrides": {
        "corpus_id": "your-corpus-id-here",
        "minimum_score": 0.8
      }
    }
  ]
}
​
Parameters
Required Parameter Override:
​
corpus_id
stringrequired
The ID of the corpus to be used for all queries.
Dynamic Parameters:
​
query
stringrequired
What to search for.
​
max_results
integerdefault:"5"
How many chunks to receive back. Can be any value from 1-20.
Static Parameters:
​
minimum_score
numberdefault:"0"
Can be used to only return content with a minimum semantic similarity score.
​
leaveVoicemail
When making outbound phone calls, used to leave a voicemail and then end the call.
A dynamic message parameter is used for the message that will be left. Optionally, you can change the hang up behavior with strict and the return message with result.
Example Usage:
Using leaveVoicemail Tool

// Basic usage
{
  "selectedTools": [
    {
      "toolName": "leaveVoicemail"
    }
  ]
}
​
Parameters
Dynamic Parameters:
​
message
stringrequired
The voicemail message to leave.
Static Parameters:
​
strict
booldefault:"true"
true ends the call regardless of user interaction. If set to false, any user interaction (i.e. speech or interrupting the voicemail) will cause the call to continue.
​
result
stringdefault:"[Leaving voicemail...]"
The message that is returned from the tool call. Will be added to conversation history.
​
hangUp
Ends the current call programmatically.
Optionally accepts a dynamic parameter called reason. A static parameter called strict can be overridden to enable the call to continue if the user speaks and continues the call.
Example Usage:
Using hangUp Tool
// Basic usage
{
  "systemPrompt": "Help users with their questions. When they say goodbye or the conversation naturally ends, use the hangUp tool to end the call politely.",
  "selectedTools": [
    { "toolName": "hangUp" }
  ]
}

// Enable soft hangup behavior
{
  "selectedTools": [
    {
      "toolName": "hangUp",
      "parameterOverrides": {
        "strict": false
      }
    }
  ]
}
​
Parameters
Dynamic Parameters:
​
reason
string
A brief reason for hanging up.
Static Parameters:
​
strict
booldefault:"true"
true ends the call regardless of user interaction. If set to false, any user interaction (i.e. speech) will cause the call to continue.
​
playDtmfSounds
Plays telephone keypad tones (dual-tone multi-frequency signals).
Requires a dynamic parameter called digits. Static parameters for toneDuration and spaceDuration can be overridden. Automatically sets the sample rate based on current call medium.
Example:
Using playDtmfSounds Tool
// Basic usage
{
  "selectedTools": [
    { "toolName": "playDtmfSounds" }
  ]
}

// Increasing length of tones and spaces
{
  "selectedTools": [
    {
      "toolName": "playDtmfSounds",
      "parameterOverrides": {
        "toneDuration": "0.5s",
        "spaceDuration": "0.3s"
      }
    }
  ]
}
​
Parameters
Dynamic Parameters:
​
digits
stringrequired
The digits for which tones should be produced. May include: 0-9, *, #, or A-D.
Static Parameters:
​
toneDuration
stringdefault:"0.2s"
The length (in seconds) that tones will be emitted.
​
spaceDuration
stringdefault:"0.1s"
The length (in seconds) that spaces (AKA silence between DTMF tones) will be emitted.
​
coldTransfer
Transfers the current call to a human operator.
Requires the transfer target. You can optionally include additional headers that will be used in the SIP REFER (or INVITE).
For bridge transfers (sip medium only), you can override the sipVerb parameter from REFER to INVITE when adding the tool to your agent or call. You may also wish to set from, username, and/or password in order to authenticate the subsequent INVITE. Note that bridge transfers will incur additional cost.
Example Usage:
Using coldTransfer Tool

// Basic usage
{
  "selectedTools": [
    {
      "toolName": "coldTransfer",
      "parameterOverrides": {
        "target": "sip:user@mytrunk.com"
      }
    }
  ]
}

// With headers and name/description overrides
{
  "selectedTools": [
    {
      "toolName": "coldTransfer",
      "nameOverride": "escalateToManager",
      "descriptionOverride": "Transfers the call to your shift manager.",
      "parameterOverrides": {
        "target": "sip:manager@mytrunk.com",
        "extraHeaders": {
          "Referred-By": "sip:agent@mytrunk.com",
          "X-Custom-Header": "customValue"
        }
      }
    }
  ]
}

// With bridge transfer (sip medium only)
{
  "selectedTools": [
    {
      "toolName": "coldTransfer",
      "nameOverride": "escalateToManager",
      "descriptionOverride": "Transfers the call to your shift manager.",
      "parameterOverrides": {
        "target": "sip:manager@mytrunk.com",
        "extraHeaders": {
          "X-Custom-Header": "customValue"
        },
        "sipVerb": "INVITE",
        "from": "+15551234567",  // Caller ID for the INVITE. Defaults to the user's number.
        "username": "authorized_user",  // Optional username for authenticating the INVITE
        "password": "password_for_authorized_user"  // Optional password for authenticating as username
      }
    }
  ]
}
​
Parameters
Required Parameter Override:
​
target
stringrequired
The target of the transfer. This is who the user’s client should be REFER’ed to. A SIP URI is always allowed. A phone number in E.164 format may be allowed depending on your medium and telephony configuration.
Optional Parameters:
​
extraHeaders
object
A string-to-string map of headers to include in the REFER (or INVITE) request. Custom headers should use the “X-” prefix to avoid conflicts with standard SIP headers.
​
holdMusicUrl
string | null
Music to play to the user while the transfer is in progress. Set to null to disable hold music. Note that hold music will not be present in Ultravox call recordings as it is added at the SIP level. If you elect to use your own hold music, make sure it is either mp3 or wav, can be downloaded without authentication, and does not exceed 5MB. Default:
​
sipVerb
string
The SIP method to use for the transfer. Can be either REFER (default) or INVITE (for bridge transfers).
​
from
string
The caller ID to use when performing an INVITE transfer. Defaults to the user’s number. (Unused for REFER transfers.)
​
username
string
Optional username for authenticating the INVITE request. (Unused for REFER transfers.)
​
password
string
Optional password for authenticating as username in the INVITE request. (Unused for REFER transfers.)
​
warmTransfer
Transfers the current call to a human operator, with a warm handoff.
Requires the transfer target. See call transfers for more details.
Example Usage:
Using warmTransfer Tool

// Basic usage
{
  "selectedTools": [
    {
      "toolName": "warmTransfer",
      "parameterOverrides": {
        "target": "sip:user@mytrunk.com"
      }
    }
  ]
}

// With more customization
{
  "selectedTools": [
    {
      "toolName": "warmTransfer",
      "nameOverride": "escalateToManager",
      "descriptionOverride": "Transfers the call to your shift manager.",
      "parameterOverrides": {
        "target": "sip:manager@mytrunk.com",
        "from": "+15551234567",  // Caller ID for the INVITE. Defaults to the user's number.
        "username": "authorized_user",  // Optional username for authenticating the INVITE
        "password": "password_for_authorized_user",  // Optional password for authenticating as username
        "inviteHeaders": {
          "X-Custom-Header": "customValue"
        },
        "transferSystemPromptTemplate": "You are a drive-thru order taker at a donut shop called \"Dr. Donut.\" You've just called your manager to transfer a customer to them. You have this context from your call with the customer:\n\n{context}",
        "referHeaders": {
          "Referred-By": "sip:agent@mytrunk.com",
          "X-Custom-Header": "customValue"
        }
      }
    }
  ]
}
​
Parameters
Required Parameter Override:
​
target
stringrequired
The target of the transfer. This is who an INVITE will be sent to for the second call. Must be a valid SIP URI.
Optional Parameters:
​
from
string
The caller ID to use for the INVITE. Defaults to the user’s number.
​
username
string
Optional username for authenticating the INVITE request.
​
password
string
Optional password for authenticating as username in the INVITE request.
​
inviteHeaders
object
A string-to-string map of extra headers to include in the INVITE request. Custom headers should use the “X-” prefix to avoid conflicts with standard SIP headers.
​
holdMusicUrl
string | null
Music to play to the user while the transfer is in progress. Set to null to disable hold music. Note that hold music will not be present in Ultravox call recordings as it is added at the SIP level. If you elect to use your own hold music, make sure it is either mp3 or wav, can be downloaded without authentication, and does not exceed 5MB. Default:
​
transferSystemPromptTemplate
string
The system prompt the agent will use when talking with the transfer target. The {context} variable may be added anywhere you like and will be replaced with context generated by the agent when invoking warmTransfer initially.
​
transferType
string
The type of transfer to perform once the human operator accepts the transfer. Can be either REFER, BRIDGE, or TRY_REFER (default). TRY_REFER will first attempt an in-session REFER and fall back on bridging the calls if the REFER fails.
​
referHeaders
object
A string-to-string map of extra headers to include in the REFER request (if any). Custom headers should use the “X-” prefix to avoid conflicts with standard SIP headers.
​
Customizing Built-in Tools
​
Overriding Tool Behavior
You can customize built-in tools by overriding their names or descriptions:
Overriding Tool Name & Description
{
  "selectedTools": [
    {
      "toolName": "hangUp",
      "nameOverride": "endConversation",
      "descriptionOverride": "Politely end the conversation when the user is satisfied with the help provided."
    }
  ]
}
​
Parameter Overrides
Some built-in tools require or allow parameter overrides:
{
  "selectedTools": [
    {
      "toolName": "queryCorpus",
      "parameterOverrides": {
        "corpus_id": "corp-123",
        "maxResults": 5
      }
    }
  ]
}
See the guide on Parameter Overrides →
​
Replacing Built-in Tools
You can override built-in tools by creating your own tool with the same name:
// Create a custom "hangUp" tool that logs before ending calls
{
  "name": "hangUp",
  "definition": {
    "modelToolName": "hangUp",
    "description": "Log conversation details and end the call",
    "http": {
      "baseUrlPattern": "https://your-api.com/log-and-hangup",
      "httpMethod": "POST"
    }
  }
}
When you reference a tool by name, your custom tool will be used instead of the built-in version.
Tool ID vs Name Priority
If you reference a tool by toolId, you’ll always get that specific tool. If you reference by toolName and have a custom tool with the same name, your custom tool takes precedence over the built-in version.
​
Authentication
Built-in tools handle authentication automatically - no additional setup required. However, some tools like queryCorpus require you to specify which corpus to search via parameter overrides.


Async Tools
Handle long-running operations and optimize tool performance for real-time conversations.

​
The Latency Challenge
In real-time conversations, tool performance is critical. When adding your own tools, it’s important to keep in mind that there’s always a user actively waiting for your tool to respond. Some operations naturally take time but tools need to be (or at least appear) fast to make sense in a real-time context.
During tool execution, conversations are essentially frozen. Users can continue talking, but the agent won’t respond until the tool completes. This creates several challenges:
User Experience: Long waits feel like connection problems.
Conversation Flow: Delays break natural conversation rhythm.
Tool Timeout: Tools are limited to 2.5 seconds by default (max of 40 seconds).
​
Tool Invocation Timing
By default, tool invocations are always included in the conversation history. This is done so that you can always understand the timing and context of all tool invocations. In cases when the LLM produces a combination of an agent utterance + a tool call, maintaining this conversation history requires delaying tool invocations until after the agent is done speaking speaking. Otherwise, there’s no way to ensure the agent wouldn’t be interrupted by the user (and potentially render the queued tool call irrelevant).
This is essential for tools that modify state since there’s no good way to revert changes if the agent is interrupted. However, it’s obviously suboptimal for tools like queryCorpus where we’d like to look up information while the agent is speaking and simply ignore the response if the agent is interrupted. Tools like this can be marked precomputable.
​
Precomputable Tools
The most effective way to handle latency is to execute tools speculatively while the agent is speaking.
Any tool marked precomputable will be speculatively invoked as soon as the model produces the tool call. When the model produces both an agent utterance and the tool call, the tool’s latency will be masked by the agent speaking, but if the agent is interrupted there will be no record of the invocation.
​
How Precomputable Tools Work
Agent generates both speech and a tool call
Precomputable tool executes immediately while agent speaks
Tool result is available when speech finishes
If agent is interrupted, tool result is discarded
Example:
Marking Tool as Precomputable
{
  "name": "lookupProduct",
  "definition": {
    "modelToolName": "lookupProduct",
    "description": "Look up product information",
    "precomputable": true, // ← Key property
    "dynamicParameters": [
      {
        "name": "productId",
        "location": "PARAMETER_LOCATION_QUERY",
        "schema": { "type": "string" },
        "required": true
      }
    ],
    "http": {
      "baseUrlPattern": "https://api.example.com/products/{productId}",
      "httpMethod": "GET"
    }
  }
}
In order to safely be marked precomputable, a tool should have three properties:
No state changes. For http tools, GET requests are usually safe while methods like POST are not.
No side effects. Even a GET request is not safe to precompute if it has a side effect! (It’s up to you to decide what counts here though. Side effects like logging probably don’t matter to you for example while any database write likely does.)
Idempotent. The tool must return the same result when called with the same parameters, regardless of when or how many times it is called.
If your tool meets these requirements, you can mark it precomputable using the corresponding field.
​
Requirements for Precomputable Tools
For a tool to be safely marked precomputable, it must be:
✅ Read-only: No state changes (GET requests are usually safe, POST requests are not).
✅ No Side Effects: No logging critical events, sending notifications, etc.
✅ Idempotent: Same input always produces same output, regardless of when or how many times it’s called.
​
Examples
✅ Good Precomputable Tools:
Database lookups
API queries for reference data
File reads or cache retrievals
Mathematical calculations
❌ Bad Precomputable Tools:
Sending emails or notifications
Database writes or updates
Payment processing
File uploads
​
Custom Tool Timeouts
While tools are executing, the conversation is essentially frozen. The user can continue talking all they like, but the agent will never respond until after the tool invocation completes. (The agent does have access to anything the user said during tool execution once execution completes.)
To users this may feel like the call was disconnected or that there was an unnatural delay. In order to avoid these causes of perceived latency, tools are limited to a default execution time of 2.5 seconds. If your tool needs longer (and you can’t make it faster), you can increase the timeout up to 40 seconds by setting the tool’s timeout field. You can also reduce your tool’s timeout. The value is a duration in seconds, like 5s for 5 seconds or 0.1s for 100 milliseconds.
Example:
Increasing Tool Timeout
{
  "name": "complexAnalysis",
  "definition": {
    "modelToolName": "complexAnalysis",
    "description": "Perform complex data analysis",
    "timeout": "10s", // ← Custom timeout (up to 40s max)
    "dynamicParameters": [
      {
        "name": "dataset",
        "location": "PARAMETER_LOCATION_BODY",
        "schema": { "type": "string" },
        "required": true
      }
    ],
    "http": {
      "baseUrlPattern": "https://api.example.com/analyze",
      "httpMethod": "POST"
    }
  }
}
For tools that take even longer, consider responding immediately and later using a user_text_message with the real tool result. This is easiest with a dataConnection implementation since data connections are also able to send input text messages (and the response is always deferred in that case). Keep in mind that the model will see whatever response you send back initially, so you’ll want to make it clear to the model what’s going on by initially responding with some text like “Tool started. The full response will be available soon.”
Custom Timeout Considerations
Start Small: Begin with default 2.5s, increase only if needed.
Set User Expectations: Tell users when operations will take time.
Fallback Plans: Handle timeout failures gracefully.





