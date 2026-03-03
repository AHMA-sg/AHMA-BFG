Overview: Agents & Calls
Create consistent, reusable voice AI experience with agents or direct call configuration.

​
Introduction
Ultravox provides two ways to create voice conversations: Agents (recommended) and Direct Calls. For all new projects, we strongly recommend starting with agents as they provide better consistency, reusability, and maintainability.
​
Agents vs Direct Calls
Agents (Recommended)

Reusable templates that define assistant behavior, personality, and capabilities. Create once, use for multiple calls.

Best for: Production applications, consistent experiences, team collaboration.
Direct Calls

One-time configurations where you specify all settings for each individual call.

Best for: Quick testing, very simple one-off use cases.
​
Why Start with Agents?
Agents provide a way to define voice assistants that can be reused across multiple calls, ensuring consistent behavior and capabilities. This enables you to maintain a cohesive user experience with minimal configuration overhead at call creation time. Each agent includes a call template that defines system prompts, voice settings, available tools, and more.
Key benefits of using Agents:
Reusable Configuration → Create a single agent definition and use it for multiple calls without repeating configuration settings.
Consistent Experience → Ensure your voice experience maintains the same personality, capabilities, and behavior across all interactions.
Version Control → Update an agent’s configuration in one place and have changes apply to all future calls.
Simplified Deployment → Reduce the complexity of starting calls by referencing an existing agent instead of providing all configuration details.

Building & Editing Agents
Create and manage reusable voice assistant templates for consistent experiences.

​
Planning Your Agent
Before creating an agent, consider these key design decisions:
1
Define Purpose & Personality

What is your agent’s role? Customer support, sales assistant, information provider? Define the personality, tone, and expertise level.
2
Identify Required Capabilities

What tools and integrations does your agent need? Knowledge base access, CRM integration, payment processing?
3
Plan Dynamic Content

What information changes between calls? Customer names, account details, product catalogs? These become template variables.
4
Choose Voice & Language

Select appropriate voice characteristics and language settings for your target audience.
​
Creating Agents
Agent Quickstart
Want to dive right in? Use our Agent Quickstart to build your first agent now.
The web app and API are fully compatible. Agents created in either can be managed through both interfaces.
​
Using the No-Code Web App
For teams preferring visual interfaces, Ultravox provides a web-based agent builder:
When to Use the Web App:
Rapid prototyping and experimentation
Non-technical team members need to create agents
Visual configuration is preferred over code
Quick testing of voice and personality combinations
When to Use the API:
Production deployments, CI/CD integration, and version control
Complex template variable schemas
Advanced tool configurations
Transitioning Between Approaches:
Start with the web app for rapid prototyping
Export configurations to API calls for production
Use the web app for quick edits, API for deployment
​
Using the API
Create agents programmatically for full control and integration with your development workflow:
Example: Creating a New Customer Support Agent
// Note: we are using a template variable for customerName
const createAgent = async () => {
  const response = await fetch('https://api.ultravox.ai/api/agents', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': 'your-api-key'
    },
    body: JSON.stringify({
      name: 'Customer Support Agent',
      callTemplate: {
        systemPrompt: "You are Anna, a friendly customer support agent for Acme Inc. You are talking to {{customerName}}. You should help them with their questions about our products and services. If you can't answer a question, offer to connect them with a human support agent.",
        voice: "Jessica",
        temperature: 0.4,
        recordingEnabled: true,
        firstSpeakerSettings: {
          agent: {
            text: "Hello! This is Anna from Acme customer support. How can I help you today?"
          }
        },
        selectedTools: [
          { toolName: 'knowledgebaseLookup' },
          { toolName: 'orderStatus' },
          { toolName: 'transferToHuman' }
        ]
      }
    })
  });
  
  return await response.json();
};
​
Call Template Configuration
The call template is the heart of your agent, defining all behavior and capabilities:
​
System Prompt
Design effective system prompts that define your agent’s personality and knowledge. Here’s an example prompt using various template variables that will be populated at call creation time using the templateContext property:
Example: Defining an Agent System Prompt
You are {{agentName}}, a {{role}} for {{companyName}}. 

Your personality: {{personality}}
Your expertise: {{expertise}}

Guidelines:
- Always be {{tone}} and professional
- If you don't know something, offer to transfer the call to a human agent using the 'transferToHuman' tool
- Keep responses concise but helpful
- Reference the customer as {{customerName}} when appropriate

Context about this conversation:
- Customer type: {{customerTier}}
- Previous interaction: {{lastInteraction}}
For more, see our Prompting Guide →
​
Voice Configuration
Choose a voice that matches your brand and audience.
Example: Built-in vs. External Voice
// Built-in Ultravox voice
voice: "Jessica"  // Professional, friendly

// External voice providers (requires API keys)
externalVoice: {
  elevenLabs: {
    voiceId: "your-elevenlabs-voice-id",
    model: "eleven_turbo_v2_5",
    speed: 1.0,
    stability: 0.8
  }
}
Learn more in the Voices Overview →
​
Tool Selection and Configuration
Connect your agent to external capabilities using tools:
Example: Defining Selected Tools
selectedTools: [
  {
    toolName: 'knowledgebaseLookup',
    descriptionOverride: 'Search our product documentation and FAQ',
    parameterOverrides: {
      maxResults: 3
    }
  },
  {
    toolName: 'orderStatus',
    authTokens: {
      apiKey: 'your-order-system-key'
    }
  },
  {
    toolName: 'transferToHuman'
  }
]
Dig into more in the Tools Overview →
​
Agent Management
​
Updating Agents
You can update the agent via the Ultravox web app or via the Update Agent API.
Example: Updating Agent via API
const updateAgent = async (agentId) => {
  const response = await fetch(`https://api.ultravox.ai/api/agents/${agentId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': 'your-api-key'
    },
    body: JSON.stringify({
      callTemplate: {
        systemPrompt: "Updated system prompt...",
        temperature: 0.4  // Only fields you want to change
      }
    })
  });
  
  return await response.json();
};
Agent changes only affect new calls. Active calls continue using the configuration they started with.
​
Monitoring and Analytics
Track agent performance and usage:
Example: Getting Agent Stats & Calls
// Get agent statistics
const getAgentStats = async (agentId) => {
  const response = await fetch(`https://api.ultravox.ai/api/agents/${agentId}`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  const agent = await response.json();
  console.log('Total calls:', agent.statistics.calls);
};

// Get recent calls for this agent
const getAgentCalls = async (agentId) => {
  const response = await fetch(`https://api.ultravox.ai/api/agents/${agentId}/calls`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};

Making Calls
Start conversations using agents or direct call configuration.

​
Creating Calls with Agents (Recommended)
For all new projects, use agents to create calls. This approach provides consistency, reusability, and easier maintenance.
​
Basic Agent Call
Start a call using an existing agent and pass in any template variables:
Example: Create a New Agent Call
const startAgentCall = async (agentId) => {
  const response = await fetch(`https://api.ultravox.ai/api/agents/${agentId}/calls`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': 'your-api-key'
    },
    body: JSON.stringify({
      templateContext: {
        customerName: "Jane Smith",
        accountType: "Premium"
      }
    })
  });
  
  return await response.json();
};
​
Template Context and Variables
Provide dynamic data to your agent at call creation time:
Example: Template Context Variables
{
  templateContext: {
    customerName: "John Doe",
    accountType: "enterprise",
    lastInteraction: "2025-05-15",
    accountBalance: "$1,250.00"
  }
}
​
Overriding Agent Settings
When starting a call with an agent, you can override specific settings from the agent’s call template. Here are the parameters you can include in the request body:
Parameter	Description	Type	Example
templateContext	Variables for template substitution	Object	{ customerName: "John" }
initialMessages	Conversation history to start from	Array	Previous chat context
metadata	Key-value pairs for tracking	Object	{ source: "website" }
medium	Communication protocol	Object	{ twilio: {} }.
joinTimeout	Time limit for user to join	String	"60s"
maxDuration	Maximum call length	String	"1800s"
recordingEnabled.	Whether to record audio	Boolean	true / false
initialOutputMedium	Start with voice or text	String	"voice" / "text"
firstSpeakerSettings	Initial conversation behavior	Object	{ agent: { text: "..." } }
experimentalSettings	Experimental settings for the call	Object	Varies
Example of overriding agent settings when creating a call:
Example: Overriding Agent Settings
const response = await fetch(`https://api.ultravox.ai/api/agents/${agentId}/calls`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'your-api-key'
  },
  body: JSON.stringify({
    // Template context
    templateContext: {
      customerName: "VIP Customer",
      accountType: "enterprise"
    },
    
    // Override agent settings for this specific call
    maxDuration: "900s", // 15 minutes instead of default
    recordingEnabled: false  // Disable call recording
  })
});
​
Direct Call Alternative
For legacy integration, testing, or very simple use cases, you can create calls directly without agents:
const startDirectCall = async () => {
  const response = await fetch('https://api.ultravox.ai/api/calls', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': 'your-api-key'
    },
    body: JSON.stringify({
      systemPrompt: "You are a helpful customer service agent. Be friendly and professional.",
      voice: "Jessica",
      temperature: 0.3,
      model: "ultravox-v0.7",
      joinTimeout: "30s",
      maxDuration: "3600s",
      recordingEnabled: false,
      
      firstSpeakerSettings: {
        agent: {
          text: "Hello! How can I help you today?"
        }
      },
      
      selectedTools: [
        { toolName: 'knowledgebaseLookup' },
        { toolName: 'transferToHuman' }
      ],
      
      metadata: {
        purpose: "customer_support",
        test: "true"
      }
    })
  });
  
  return await response.json();
};
​
Prior Call Inheritance
You can reuse the same properties (including message history) from a prior call by passing in a query param:
Example: Using Prior Call ID
const continueFromPriorCall = async (priorCallId) => {
  const response = await fetch(`https://api.ultravox.ai/api/calls?priorCallId=${priorCallId}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': 'your-api-key'
    },
    body: JSON.stringify({
      // Only override what you need to change
      systemPrompt: "Continue the previous conversation with updated context...",
      metadata: {
        continuation: "true",
        originalCall: priorCallId
      }
    })
  });
  
  return await response.json();
};
When using priorCallId, the new call inherits all properties from the prior call unless explicitly overridden. The prior call’s message history becomes the new call’s initialMessages.

Call Management
Retrieve call information, from active conversation monitoring to historical data analysis and cleanup.

​
Monitoring Active Calls
Track ongoing conversations across your application:
// List all calls with filtering
const getActiveCalls = async () => {
  const response = await fetch('https://api.ultravox.ai/api/calls?pageSize=50', {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  const data = await response.json();
  
  // Filter for active calls (those that are joined but not ended)
  const activeCalls = data.results.filter(call => 
    call.joined && !call.ended
  );
  
  return activeCalls;
};

// Get calls with specific metadata
const getCallsBySource = async (source) => {
  const params = new URLSearchParams({
    'metadata.source': source,
    pageSize: 100
  });
  
  const response = await fetch(`https://api.ultravox.ai/api/calls?${params}`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};
​
Advanced Filtering
Use query parameters to find specific calls:
// Filter by date range and duration
const getRecentLongCalls = async () => {
  const params = new URLSearchParams({
    fromDate: '2024-01-01',
    toDate: '2024-01-31',
    durationMin: '300s',  // 5 minutes or longer
    sort: '-created'      // Newest first
  });
  
  const response = await fetch(`https://api.ultravox.ai/api/calls?${params}`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};

// Search calls by content
const searchCalls = async (searchTerm) => {
  const params = new URLSearchParams({
    search: searchTerm,
    pageSize: 20
  });
  
  const response = await fetch(`https://api.ultravox.ai/api/calls?${params}`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};
​
Retrieving Call Details
Get comprehensive information about specific calls:
// Get call details
const getCallDetails = async (callId) => {
  const response = await fetch(`https://api.ultravox.ai/api/calls/${callId}`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  const call = await response.json();
  
  console.log('Call Status:', call.ended ? 'Completed' : 'Active');
  console.log('Duration:', call.ended ? 
    calculateDuration(call.joined, call.ended) : 'Ongoing');
  console.log('End Reason:', call.endReason);
  
  return call;
};

// Get conversation messages
const getCallMessages = async (callId) => {
  const response = await fetch(`https://api.ultravox.ai/api/calls/${callId}/messages`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};

// Get call events and logs
const getCallEvents = async (callId) => {
  const response = await fetch(`https://api.ultravox.ai/api/calls/${callId}/events`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};
​
Working with Call Stages
For calls using Call Stages, use stage-specific endpoints:
// Get all stages for a call
const getCallStages = async (callId) => {
  const response = await fetch(`https://api.ultravox.ai/api/calls/${callId}/stages`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};

// Get messages for a specific stage
const getStageMessages = async (callId, stageId) => {
  const response = await fetch(
    `https://api.ultravox.ai/api/calls/${callId}/stages/${stageId}/messages`,
    { headers: { 'X-API-Key': 'your-api-key' } }
  );
  
  return await response.json();
};
​
Call Recordings
Retrieve audio recordings when recording is enabled:
// Get call recording
const getCallRecording = async (callId) => {
  const response = await fetch(`https://api.ultravox.ai/api/calls/${callId}/recording`, {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  if (response.ok) {
    const audioBlob = await response.blob();
    // Handle audio data (save to file, play, etc.)
    return audioBlob;
  } else {
    console.log('Recording not available');
    return null;
  }
};
​
Call Deletion
Remove calls and all associated messages, recordings, and stages:
// Delete a specific call
const deleteCall = async (callId) => {
  const response = await fetch(`https://api.ultravox.ai/api/calls/${callId}`, {
    method: 'DELETE',
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return response.ok;
};
​
List Deleted Calls
When calls are deleted, we retain basic metadata for record keeping:
// View deleted calls (tombstone records)
const getDeletedCalls = async () => {
  const response = await fetch('https://api.ultravox.ai/api/deleted_calls', {
    headers: { 'X-API-Key': 'your-api-key' }
  });
  
  return await response.json();
};

Guiding Agents
A guide to steering your agent toward good experiences

​
Introduction to Inline Instructions
Inline instructions use tool responses and deferred messages to guide the agent at each step of the conversation. Rather than trying to frontload all instructions, you continuously remind the agent of what to do next.
This guide is intended to help you get better outcomes from an agent where mono prompting isn’t cutting it. If you haven’t tried a mono prompt approach yet, stop reading and go do that first. This guide is for you if:
Monoprompting Isn’t Working → You’ve tried mono prompting but things are not working. The agent won’t complete necessary steps or follow more complex instructions.
You Have Clear Steps → There are clear steps you want the agent to follow (e.g. asking the user 10 specific questions) and you can map to a state diagram.
Building an IVR?
If you are building an IVR or if your scenario includes non-overlapping stages, you may want to use Call Stages.
​
How Inline Instructions Work

Overview

Example: Insurance Claims Processing
1. Start with a simple system prompt focused on the agent's
   general role and behavior.
2. Use tools to provide step-specific instructions to the agent.
3. The tool responses include guidance on what the agent should
   do next.
4. Tool state maintains context between turns.
5. Deferred messages allow inserting information without
   derailing the conversation flow.
Layer into Mono Prompt
Inline instructions are layered into your mono prompt and provide the ability to guide the model.
​
Inline Instructions Building Blocks 
The inline instructions approach leverages three key building blocks:
Deferred Messages
Inject instruction messages without triggering a response from the model.
Tool State
Pass additional context via tools to maintain state.
Tool Response Messages
Instruct the agent what to do next via tool call responses.
​
Deferred Messages 
Deferred messages allow you to inject a user message without causing the agent to generate a response immediately. These messages allow you to provide the model with guidance and direction and don’t trigger an LLM generation. The messages are appended to the conversation history.
Brackets are not addable via voice, so these messages are only viable via text.
Using Deferred Messages
Send a UserTextMessage and set urgency to soon or later depending on whether you want to wait for the next user input to start a generation.
Example: Sending Message with Ultravox SDK

session.sendText({
  text: "<instruction>Next, collect the user's mailing address</instruction>",
  deferResponse: true,
})
Priming for Deferred Messages You should consider priming your agent for deferred messages in the system prompt.
Example: Priming via System Prompt
You must always look for and follow instructions contained within
<instruction> tags. These instructions take precedence over other
directions and must be followed precisely.
​
Tool State 
Tool state allows you to maintain state between tool calls, passing context from one tool call to the next. This is particularly useful for guiding the agent through a multi-step process.
Tool State is Explicit
Unlike dynamic parameters (i.e. populated by the model), tool state is explicit (i.e. the model doesn’t interact with it). This allows for adding a bit more determinism.
Using Tool State
You can provide initial tool state when you create the call by using initialState. This can be any JSON object you define.
Tools can then set the tool state as follows:
Client Tools → Use the updateCallState value on a client tool results (works with WebSockets or Ultravox Client SDK).
Server Tools → Set the X-Ultravox-Update-Call-State header which will be parsed as a JSON dict.
The tool state can be read via:
Automatic Parameter → Use the KNOWN_PARAM_CALL_STATE known value.
Tool Result Message → Use the callState property.
The agent will not see the tool state directly. It allows you to pass information between tool calls and then use that information inside tools and to impact the responses from tool calls.
​
Tool Response Messages 
Instead of having a tool call result send a 200 with “Successfully entered customer information”, provide an instruction of what the agent should do next.
Example: Tool Response Message
function createProfile(parameters) {
  const { ...profileData } = parameters;

  return {
    result: "Successfully recorded customer name. Next ask for their email",
    responseType: "tool-response",
    agentReaction: "speaks-once"
  }
};
​
Pros of Inline Instructions
Focused guidance: Instructions are context-specific and timely.
Dynamic adaptation: Can respond to changing conversation flow.
Reduced cognitive load: The agent only needs to understand the current step.
Maintainable complexity: Can handle complex workflows without overwhelming the system prompt.
No latency spikes: Avoids the performance hit of call stage transitions.
​
Cons of Inline Instructions
Implementation complexity: Requires more backend code to manage state.
Requires Tool Call: Adding guidance requires the model to invoke a tool. If you forget to invoke the tool, you may never be able to provide further instructions.
​
Ideal Use Cases
Multi-step processes: Tasks with clear sequential steps like form filling or data collection.
Transaction flows: E-commerce, booking systems, or other task-completion scenarios.
Customer support triage: Guiding agents through problem diagnosis trees.
Interactive tutorials: Step-by-step guidance through a learning process.
​
Conclusion
Keeping your AI agent “on rails” is a balance between control and natural conversation. The right approach depends on your specific use case:
Mono Prompt: Always start here. Graduate to using inline instructions if and when needed.
Inline Instructions: For complex, multi-step processes requiring dynamic guidance.
Call Stages: For conversations with fundamentally different phases (i.e. no overlap) requiring complete parameter changes.

Call Stages
Create dynamic, multi-stage conversations.

The Ultravox API’s Call Stages functionality allows you to create dynamic, multi-stage conversations. Stages enable more complex and nuanced agent interactions, giving you fine-grained control over the conversation flow.
Each stage can have a new system prompt, a different set of tools, a new voice, an updated conversation history, and more.
Advanced Feature
Call stages require planning and careful implementation and are likely not required for simple use cases. Make sure to read Guiding Agents before jumping into the deep end of stages.
​
Understanding Call Stages
Call Stages (“Stages”) provide a way to segment a conversation into distinct phases, each with its own system prompt and potentially different parameters. This enables interactions that can adapt and change focus as the conversation progresses.
Key points to understand about Stages:
Dynamic System Prompts → Stages allow you to give granular system prompts to the model as the conversation progresses.
Flexibility → You have full control to determine when and how you want the conversation to progress to the next stage.
Thoughtful Design → Implementing stages requires careful planning and consideration of the conversation structure. Consider how to handle stage transitions and test thoroughly to ensure a natural flow to the conversation.
Maintain Context → Think about how the agent will maintain context about the user between stages if you need to ensure a coherent conversation.
​
Creating and Managing Stages
To implement Call Stages in your Ultravox application, follow these steps:
1
Plan Your Stages

Determine the different phases of your conversation and what prompts or parameters should change at each stage.
2
Implement a Stage Change Tool

Create a custom tool that will trigger stage changes when called. This tool should:
Respond with a new-stage response type. This creates the new stage. How you send the response depends on the tool type:
For server/HTTP tools, set the X-Ultravox-Response-Type header to new-stage.
For client tools, set responseType="new-stage" on your ClientToolResult object.
Provide the updated parameters (e.g., system prompt, tools, voice) for the new stage in the response body.
Unless overridden, stages inherit all properties of the existing call. See Stages Call Properties for the list of call properties that can be changed.
3
Configure Stage Transitions

Prompt the agent to use the stage change tool at appropriate points in the conversation.
Ensure the stage change tool is part of selectedTools when creating the call as well as during new stages (if needed).
Update your system prompt as needed to instruct the agent on when/how to use the stage change tool.
Things to Remember
New stages inherit all properties from the previous stage unless explicitly overridden.
Refer to Stages Call Properties to understand which call properties can be changed as part of a new stage.
Test your stage transitions thoroughly to ensure the conversation flows naturally.
​
Example Stage Change Implementation
Here’s a basic example of how to implement a new call stage.
First, we create a tool that is responsible for changing stages:
function changeStage(requestBody) {
  const responseBody = {
    systemPrompt: "...", // new prompt
    ..., // other properties to change, like the voice
    // You may optionally also set toolResultText, which will be the content
    // of the tool result message in conversation history. The tool result
    // will be the most recent message the model sees during its next generation
    // unless you set initialMessages. Defaults to "OK".
    toolResultText: "(New Stage) Next, focus on..."
  };

  return {
    body: responseBody,
    headers: {
      'X-Ultravox-Response-Type': 'new-stage'
    }
  };
}
We also need to ensure that we have instructed our agent to use the tool and that we add the tool to our selectedTools during the creation of the call.
// Instruct the agent on how to use the stage management tool
// Add the tool to selectedTools
{
  systemPrompt: "You are a helpful assistant...you have access to a tool called changeStage...",
  ...
  selectedTools: [
    {
      "temporaryTool": {
        "modelToolName": "changeStage",
        "description": ...,
        "dynamicParameters": [...],
      }
    }
  ]
}
Inheritance
New stages inherit all properties from the previous stage. You can selectively overwrite properties as needed when defining a new stage.
See Stages Call Properties for more.
​
Ultravox API Implications
If you are not using stages for a call, retrieving calls or call messages via the API (e.g. List Calls) works as expected.
However, if you are using call stages then you most likely want to use the stage-centric API endpoints to get stage-specific settings, messages, etc.
Use List Call Stages to get all the stages for a given call.
Ultravox API	Stage-Centric Equivalent
Get Call	Get Call Stage
List Call Messages	List Call Stage Messages
List Call Tools	List Call Stage Tools
​
Stages Call Properties
The schema used for a Stages response body is a subset of the request body schema used when creating a new call. The response body must contain the new values for any properties you want to change in the new stage.
Unless overridden, stages inherit all properties of the existing call.
Here is the list of all call properties that can and cannot be changed during a new stage:
property	change with new stage?
systemPrompt	Yes
temperature	Yes
voice	Yes
languageHint	Yes
initialMessages	Yes
selectedTools	Yes
firstSpeaker	No
model	No
joinTimeout	No
maxDuration	No
timeExceededMessage	No
inactivityMessages	No
medium	No
recordingEnabled	No
​
Use Cases for Call Stages
Call Stages are particularly useful for complex conversational flows. Here are some example scenarios:
Data Gathering → Scenarios where the agent needs to collect a lot of data. Examples: job applications, medical intake forms, applying for a mortgage.
Here are potential stages for a Mortgage Application:
Stage 1: Greeting and basic information gathering
Stage 2: Financial assessment
Stage 3: Property evaluation
Stage 4: Presentation of loan options
Stage 5: Hand-off to loan officer
Switching Contexts → Scenarios where the agent needs to navigate different contexts. Examples: customer support escalation, triaging IT issues.
Let’s consider what the potential stages might be for Customer Support:
Stage 1: Initial greeting and problem identification
Stage 2: Troubleshooting
Stage 3: Resolution or escalation (to another stage or to a human support agent)
​
Conclusion
Call Stages in the Ultravox API give you the ability to create adaptive conversations for more complex scenarios like data gathering or switching contexts. By allowing granular control over system prompts and conversation parameters at different stages, you can create more dynamic and context-aware interactions.



