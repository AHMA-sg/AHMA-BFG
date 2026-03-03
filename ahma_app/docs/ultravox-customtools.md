verview: Custom Tools
Create powerful integrations that enable your agent to communicate with external systems and perform real-world actions.

Custom tools enable you to communicate with the outside world. Anything that you can do in a function can now be done by your agent via a custom tool.
Adding Tools for an Existing API
If you already run a server with a well-defined OpenAPI spec, you can quickly create tools for all your API endpoints by uploading that spec. Your OpenAPI spec must be either json or yaml format.
Once uploaded, your tools are just like any other durable tool, so you can use, modify, or delete them as you wish.
​
Creating Your First Custom Tool
Let’s look at creating a tool that sends an email with a summary of the conversation.
There are three steps:
​
Step 1:  Define the Tool
We need to define the tool and provide it to our agent. The name, description, and parameters we provide here will be seen by the agent so we need to be thoughtful with them.
Creating a custom tool
// Creating a tool called 'sendConversationSummary'
//
// A 'string' parameter named 'conversationSummary'
// is passed in the body of a POST request to https://foo.bar/sendSummary
{
  "systemPrompt": "You are a helpful assistant...",
  "selectedTools": [
    {
      "temporaryTool": {
        "modelToolName": "sendConversationSummary",
        "description": "Use this tool at the end of a conversation to send the caller a summary of the conversation.",
        "dynamicParameters": [
          {
            "name": "conversationSummary",
            "location": "PARAMETER_LOCATION_BODY",
            "schema": {
              "description": "A 2-3 sentence summary of the conversation.",
              "type": "string"
            },
            "required": true
          }
        ],
        "http": {
          "baseUrlPattern": "https://foo.bar/sendSummary",
          "httpMethod": "POST"
        }
      }
    }
  ]
}
What’s happening here:
We are adding selectedTools to the request body of the Create Call API request.
There’s a single tool named sendConversationSummary.
This tool requires a single dynamic parameter called conversationSummary that is passed in the request body.
The tool’s functionality is available via POST at the url https://foo.bar/sendSummary.
The tool is a temporary tool, so it will only be available for this call.
​
Step 2:  Implement the Function
Now that we’ve defined the tool, let’s implement the functionality. This is a simplified example using Express.js and imagines a generic email API provider.
Simple API endpoint
const express = require('express');
const router = express.Router();

router.post('/sendSummary', async (req, res) => {
  try {
    const { conversationSummary } = req.body;

    // Send the email using our email provider
    sendEmail(conversationSummary);

    return res.status(200).json({
      message: 'Conversation summary sent successfully. Continue the conversation with the user.'
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
This function does the following:
Accepts the conversationSummary via a POST.
Passes the data along to another function (sendEmail) that will send it via email.
​
Step 3:  Instruct the Agent on Tool Use
The last thing we need to do is provide additional instructions to the agent on how to use the tool. This is primarily done using the tool’s own description along with the systemPrompt. Let’s update what we used in the first step.
Prompting the agent on how to use the tool
const updatedPrompt = `
You're a friendly and fun guy. You like to chat casually while learning 
more about the person you're chatting with (name, hobbies, likes/dislikes).

Be casual. Be fun to chat with. Don't talk too much. Keep your sentences 
pretty short and fun. Let the user guide the conversation.

As you chat, try and learn more about the person you are talking to such 
as their name, hobbies, and their likes/dislikes.

Once you have all the information, call the 'sendSummary' tool to send 
a summary of the conversation.
`;
{
  "systemPrompt": updatedPrompt,
  "selectedTools": [
      // Same as before
  ]
}
We’ve updated the system prompt that is used when the Ultravox call is created to instruct the agent when and how to use the tool.
​
Debugging Tool Calls
The Ultravox SDK enables viewing debug messages for any active call. These messages include tool calls.
​
Keep Learning
Learn all about Tool Parameters →
Learn how to secure tool calls in Tool Authentication →
Check out our API reference for all tools endpoints.

Tool Parameters
Learn about dynamic, static, and automatic tool parameters.

Tool parameters define what gets passed to your backend function when the tool is called. When creating a tool, parameters are defined as one of three types:
1
Dynamic

The model will choose which values to pass. These are the parameters you’d use for a single-generation LLM API.
2
Static

This value is known when the tool is defined and is unconditionally set on invocations. The parameter is not exposed to or set by the model.
3
Automatic

Like “Static”, except that the value may not be known when the tool is defined but will instead be populated by the system when the tool is invoked.
​
Dynamic Parameters
Dynamic parameters will have their values set by the model. Creating a dynamic parameter on a tool looks like this:
Adding a dynamic parameter to a tool
// Adding a dynamic parameter to a stock price tool
// The parameter will be named 'symbol' and will be passed as a query parameter
{
  "name": "stock_price",
  "description": "Get the current stock price for a given symbol",
  "dynamicParameters": [
    {
      "name": "symbol",
      "location": "PARAMETER_LOCATION_QUERY",
      "schema": {
        "type": "string",
        "description": "Stock symbol (e.g., AAPL for Apple Inc.)"
      },
      "required": true
    }
  ]
}
​
Parameter Overrides
You can choose to set static values for dynamic parameters when you create an agent or start a call. The model won’t see any parameters that you override. When creating a call simply pass in the overrides with each tool, as below. You should also consider overriding the tool name or description to give the model a more specific understanding of what the tool will do in this case.
Overriding a dynamic parameter with a static value
// Overriding dynamic parameter when starting a new call
// Always set the stock symbol to 'NVDA'
{
  "systemPrompt": ...
  "selectedTools": [
    "toolName": "stock_price",
    "nameOverride": "nvidia_stock_price",
    "descriptionOverride": "Looks up the current stock price for Nvidia.",
    "parameterOverrides": {
      "symbol": "NVDA"
    }
  ]
}
​
Static Parameters
If you have parameters that are known at the time you create the tool, static parameters can be used. Static parameters are not exposed to or set by the LLM.
Adding a static parameter to a tool
// Adding a static parameter that always sends utm=ultravox
{
  "name": "stock_price",
  "description": "Get the current stock price for a given symbol",
  "staticParameters": [
    {
      "name": "utm",
      "location": "PARAMETER_LOCATION_QUERY",
      "value": "ultravox"
    }
  ]
}
​
Parameter Overrides
Static parameters can also be overridden when you create an agent or start a call. This is most useful with built-in tools. For example, the built-in queryCorpus tool allows you to statically override max_results.
See queryCorpus Tool → for more.
​
Automatic Parameters
Automatic parameters are used when you want a consistent, predictable value (not generated by the model) but you don’t know the value when the tool is created.
Here are some of the most common automatic parameters:
knownValue	Description
KNOWN_PARAM_CALL_ID	Used for sending the current Ultravox call ID to the tool.
KNOWN_PARAM_CONVERSATION_HISTORY	Includes the full conversation history leading up to this tool call. Typically should be in the body of a request.
KNOWN_PARAM_CALL_STATE	Includes arbitrary state previously set by tools. See Guiding Agents.
More details can be found in the Tool Definition Schema →
Adding an automatic parameter to a tool
// Adding automatic parameters to a profile creation tool
// There are two parameters added:
// 'call_id' which is sent as a query param
// 'conversation_history' which is sent in the request body
{
  "name": "create_profile",
  "description": "Creates a profile for the current caller",
  "automaticParameters": [
    {
      "name": "call_id",
      "location": "PARAMETER_LOCATION_QUERY",
      "knownValue": "KNOWN_PARAM_CALL_ID"
    },
    {
      "name": "conversation_history",
      "location": "PARAMETER_LOCATION_BODY",
      "knownValue": "KNOWN_PARAM_CONVERSATION_HISTORY"
    }
  ]
}
​
Required Parameter Overrides
Sometimes your tool will require a parameter to function that you need to have defined when the call is created instead of having the model come up with a value. In these cases, you can require that the parameter be overridden at call creation. For example, the built-in queryCorpus tool requires the corpus id to be specified during call creation.

Tool Authentication
How to use auth tokens with tools.

Ultravox has rich support for tool auth. When creating a tool, you must specify what is required for successful authentication to the backend service.
​
Methods for Passing Keys
Three methods for passing API keys are supported and are used when creating the tool.
​
Method 1: Query Parameter
The API key will be passed via the query string. The name of the parameter must be provided when the tool is created.
Creating a tool with a query param auth key
// Create a tool that uses a query parameter called 'apiKey'
{
  "name": "stock_price"
  "definition": {
    "description": "Get the current stock price for a given symbol",
    "requirements": {
      "httpSecurityOptions": {
        "options": [
          "requirements": {
            "myServiceApiKey": {
              "queryApiKey": {
                "name": "apiKey"
              }
            }
          }
        ]
      }
    }
  }
}
Providing the auth key during call creation
// Pass the API key during call creation
// Requests will include ?apiKey=your_token_here in the url
{
  "systemPrompt": ...
  "selectedTools": [
    {
      "toolName": "stock_price"
      "authTokens": {
        "myServiceApiKey": "your_token_here"
      }
    }
  ]
}
​
Method 2: Header
The API key will be passed via a custom header. The name of the header must be provided when the tool is created.
Creating a tool with a custom header auth key
// Create a tool that uses an HTTP Header named 'X-My-Header'
{
  "name": "stock_price"
  "definition": {
    "description": "Get the current stock price for a given symbol",
    "requirements": {
      "httpSecurityOptions": {
        "options": [
          "requirements": {
            "myServiceApiKey": {
              "headerApiKey": {
                "name": "X-My-Header"
              }
            }
          }
        ]
      }
    }
  }
}
Providing the auth key during call creation
// Pass the API key during call creation
// Requests will include the header "X-My-Header: your_token_here"
{
  "systemPrompt": ...
  "selectedTools": [
    {
      "toolName": "stock_price"
      "authTokens": {
        "myServiceApiKey": "your_token_here"
      }
    }
  ]
}
​
Method 3: HTTP Authentication
The API key will be passed via the HTTP Authentication header. The name of the scheme (e.g. Bearer) must be provided when the tool is created.
Creating a tool that passes auth key via HTTP Authentication header
// Create a tool that uses HTTP Authentication scheme 'Bearer'.
{
  "name": "stock_price"
  "definition": {
    "description": "Get the current stock price for a given symbol",
    "requirements": {
      "httpSecurityOptions": {
        "options": [
          "requirements": {
            "myServiceApiKey": {
              "httpAuth": {
                "scheme": "Bearer"
              }
            }
          }
        ]
      }
    }
  }
}
Providing the auth key during call creation
// Pass the API key during call creation
// Requests will include the header "Authorization: Bearer your_token_here"
{
  "systemPrompt": ...
  "selectedTools": [
    {
      "toolName": "stock_price"
      "authTokens": {
        "myServiceApiKey": "your_token_here"
      }
    }
  ]
}
​
Multiple Options Supported
Your tool can specify multiple options for fulfilling auth requirements (for example if your server allows either query or header auth). Each option may also contain multiple requirements, for example if your server requires both a user_id and an auth_token for that user.
​
Passing Keys at Call Creation Time
When defining an agent or creating a call, you pass in the key(s) in the authTokens property of selectedTools. If the tokens you provide satisfy multiple options, the first non-empty option whose requirements are all satisfied will be used. An unauthenticated option, if present, will only be used if no other option can be satisfied.

Agent Responses to Tools
Configure when and how your agent responds after tool calls - whether to speak immediately, listen for input, or speak conditionally.

​
Post-Tool Call Behavior
By default, the agent speaks again immediately after a tool call. This is typically the desired behavior for tools that gather information since the agent can immediately respond based on the information retrieved.
However, this may make less sense for other tools. For example, if your agent is gathering information for the user and you have a tool that allows the agent to store what’s been gathered so far, you may want the agent to speak either before or after the tool but not both.
Ultravox Realtime allows you to define how the agent reacts after a tool call by setting the agent reaction. A default can be set on the tool itself or you can use either the X-Ultravox-Agent-Reaction header (for http tools) or the agent_reaction field on the tool result message (for client and data connection tools) similar to how you’d set a response type (see above).
Reaction	Description
speaks	Agent will speak immediately after the tool call returns. This is the default behavior if agent reaction is not set. Should be used for tools that gather information.
listens	Agent listens for user input and doesn’t speak.
speaks-once	Agent speaks only if it didn’t speak immediately before the tool call. Prevents agent repeating things before and after the tool call.

Changing Call State
Learn how to programmatically end calls or transition between call stages using special tool response types.

​
Special Tool Response Types
For most tools, the response will include data you want the model to use (e.g. the results of a lookup). However, Ultravox has support for special tool actions that can end the call or change the call stage.
These tool actions require setting a special response type.
Response Type	Tool Action
hang-up	Terminates the call. In addition to having Ultravox end the call after periods of user inactivity, your custom tool can end the call.
new-stage	Creates a new call stage. See here for more.
How you set the response type depends on your tool implementation. HTTP tools set the response type via the X-Ultravox-Response-Type header. Client and data connection tools should set the responseType field in their tool result message.

HTTP vs. Client Tools
Choose the right tool implementation for your use case.

Real Tool Execution
Unlike using tools with single-generation LLM APIs, Ultravox Realtime actually calls your tool. This means you need to do a bit more work upfront in defining tools with the proper authentication and parameters.
Ultravox supports three primary types of tool implementations: HTTP tools, Client tools, and Data Connection tools. Each has distinct advantages and use cases.
​
HTTP Tools
HTTP tools (AKA “server tools”) are the most common and flexible option. Your tool runs on your server, and Ultravox calls it via HTTP requests during conversations.
​
How HTTP Tools Work
Agent triggers tool during conversation.
Ultravox sends HTTP request to your server.
Your server processes the request and returns a response.
Agent continues conversation with the tool result.
Example HTTP tool definition
{
  "temporaryTool": {
    "modelToolName": "lookupCustomer",
    "description": "Look up customer information by phone number",
    "dynamicParameters": [
      {
        "name": "phoneNumber",
        "location": "PARAMETER_LOCATION_BODY",
        "schema": {
          "type": "string",
          "description": "Customer's phone number"
        },
        "required": true
      }
    ],
    "http": {
      "baseUrlPattern": "https://your-api.com/customers/lookup",
      "httpMethod": "POST"
    }
  }
}
​
HTTP Tool Advantages
✅ Server-side logic: Full access to databases, APIs, and business logic
✅ Any call medium: Works with WebRTC, telephony, and websockets
✅ Scalable: Runs on your infrastructure with your scaling strategies
✅ Secure: Keep sensitive data and credentials on your servers
✅ Language agnostic: Implement in any programming language
​
HTTP Tool Implementation
Example of a simple API endpoint for HTTP tool
// Express.js example
app.post('/customers/lookup', async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    
    // Look up customer in database
    const customer = await db.customers.findByPhone(phoneNumber);
    
    if (!customer) {
      return res.status(200).json({
        message: "No customer found with that phone number. Please verify the number and try again."
      });
    }
    
    return res.status(200).json({
      message: `Found customer: ${customer.name}, Account type: ${customer.tier}, Last contact: ${customer.lastContact}`
    });
  } catch (error) {
    return res.status(500).json({
      message: "Unable to look up customer information at this time."
    });
  }
});
​
Error Handling
Return appropriate HTTP status codes:
// Success
res.status(200).json({ message: "Operation completed" });

// Client error  
res.status(400).json({ message: "Invalid input provided" });

// Server error
res.status(500).json({ message: "Internal server error" });
​
Client Tools
Client tools run directly in the client application using our SDKs. They’re perfect for UI interactions and client-side operations.
Client tools work best with our client SDKs, which are designed for the webrtc call medium. See Client Tools to learn how those are registered and used with the Ultravox Client SDK.
You can also use client tools with a websocket medium. See the ClientToolInvocation and ClientToolResult data messages.
If you want a similar experience to client tools with a telephony medium, you have two options:
Handle telephony using voximplant and define your tools in your voximplant session code.
Use a Data Connection Tool.
​
How Client Tools Work
Agent triggers tool during conversation.
Ultravox sends tool invocation to your client.
Your client code executes the tool logic.
Client sends result back to Ultravox.
Agent continues conversation with the tool result.
Example client tool definition
{
  "temporaryTool": {
    "modelToolName": "updateUserInterface",
    "description": "Update the user interface to show relevant information",
    "dynamicParameters": [
      {
        "name": "content",
        "location": "PARAMETER_LOCATION_BODY",
        "schema": {
          "type": "string",
          "description": "Content to display in the UI"
        },
        "required": true
      }
    ],
    "client": {}
  }
}
​
Client Tool Advantages
✅ UI integration: Direct access to update interface elements
✅ Low latency: No network round trip to your servers
✅ Client-side data: Access to local storage, camera, microphone
✅ Real-time updates: Immediate visual feedback
​
Client Tool Implementation
Example of client tool implementation
// Using Ultravox Client SDK
import { UltravoxSession } from 'ultravox-client';

const session = new UltravoxSession();

// Register client tool handler
session.registerClientTool("updateUserInterface", (parameters) => {
  const { content } = parameters;
  
  // Update your UI
  document.getElementById('chat-display').innerHTML = content;
  
  return {
    responseText: "Interface updated successfully",
    responseType: "tool-response"
  };
});
​
Error Handling
Return error information in the response:
return {
  responseText: "Unable to update interface: element not found",
  responseType: "tool-response"
};
​
Data Connection Tools
A third option combines benefits of both: Data Connection tools run on your server but communicate via websocket, enabling both server-side logic and real-time capabilities.
Data connections are like another participant in your call. Like the client, they can receive tool invocation messages and can send back tool result messages. Implementation lives in your websocket server and can be used regardless of the call medium used.
Example Data Connection tool definition
{
  "temporaryTool": {
    "modelToolName": "processPayment",
    "description": "Process a payment transaction",
    "dataConnection": {}
  }
}
Data connection tools are ideal for:
Long-running operations
Real-time data streaming
Complex server operations that need immediate feedback
​
Choosing the Right Tool Type
Use HTTP Tools When:
Accessing databases or external APIs
Processing sensitive data
Performing server-side calculations
Sending emails or notifications
Working with telephony (Twilio, etc.)
Need authentication with external services
Use Client Tools When:
Updating user interface elements
Accessing client device features (camera, microphone)
Performing client-side validation
Managing local application state
Need immediate visual feedback
Working with WebRTC calls primarily
Use Data Connection Tools When:
Need both server logic and real-time feedback
Handling long-running operations
Streaming real-time data
Complex workflows requiring immediate updates
​
Call Medium Compatibility
Tool Type	WebRTC	Websocket	Telephony
HTTP	✅	✅	✅
Client	✅	✅	❌
Data Connection	✅	✅	✅
​
Authentication
HTTP Tools: Full authentication support including API keys, tokens, and custom headers. See Tools Authentication →
Client Tools: No built-in authentication - handle security in your client application.
Data Connection Tools: Authentication handled via websocket connection setup.


Durable vs. Temporary Tools
Understand when to use durable tools versus temporary tools for different development stages and use cases.

Custom tools in Ultravox come in two varieties: durable and temporary. Understanding when to use each type is crucial for effective development and production deployment. Choose the approach that fits your development stage and team structure. Consider starting with temporary tools for rapid development, then graduate to durable tools for production stability and team collaboration.
​
Quick Comparison
Aspect	Temporary Tools	Durable Tools
Creation	In call request body	Via Tools API or the Web app
Persistence	Call-scoped only	Permanently stored
Reusability	Single call	Across calls and agents
​
Ultravox Web App Integration
Web App Compatibility
If you plan to use agents in the Ultravox web app or share them with team members who use the web app, you must use durable tools. Temporary tools are only available for agents created via API.
​
Agents Created in Web App
✅ Durable Tools: Can be selected and used
❌ Temporary Tools: Not supported
​
Agents Created via API
✅ Durable Tools: Can be referenced by name or ID
✅ Temporary Tools: Can be defined inline
// API-created agent with both tool types
{
  "name": "Hybrid Agent",
  "callTemplate": {
    "selectedTools": [
      { "toolName": "durableTool" },        // Durable tool
      { "temporaryTool": { /* definition */ } } // Temporary tool
    ]
  }
}
​
Temporary Tools
Temporary tools are defined inline when creating a call and exist only for that specific call session.
​
When to Use Temporary Tools
✅ Early Development: Rapid prototyping and experimentation.
✅ Testing New Ideas: Quick iteration without overhead of separately creating or updating the tool.
✅ One-off Use Cases: Tools needed for a single specific call.
✅ Development Environment: Testing before creating durable versions.

Parameter Overrides
Advanced parameter customization for fine-tuned tool behavior across different agents and calls.

Parameter overrides allow you to customize tool behavior without modifying the base tool definition. This powerful feature enables tool reuse across different contexts while maintaining specific configurations for each use case.
​
Parameter Override Capabilities
​
Override Dynamic Parameters
Convert dynamic parameters to static values for specific use cases:
// Base tool: Generic stock lookup
{
  "name": "stockPrice",
  "definition": {
    "modelToolName": "stockPrice",
    "description": "Get current stock price for any symbol",
    "dynamicParameters": [
      {
        "name": "symbol",
        "location": "PARAMETER_LOCATION_QUERY",
        "schema": {
          "type": "string",
          "description": "Stock symbol (e.g., AAPL, GOOGL)"
        },
        "required": true
      }
    ]
  }
}

// Override for NVIDIA-specific agent
{
  "selectedTools": [
    {
      "toolName": "stockPrice",
      "nameOverride": "nvidiaStockPrice",
      "descriptionOverride": "Get current NVIDIA stock price",
      "parameterOverrides": {
        "symbol": "NVDA" // AI won't see this parameter anymore
      }
    }
  ]
}
​
Override Static Parameters
Modify static parameter values for different environments or configurations:
// Base tool with production API endpoint
{
  "name": "processPayment",
  "staticParameters": [
    {
      "name": "environment",
      "location": "PARAMETER_LOCATION_BODY",
      "value": "production"
    },
    {
      "name": "timeout",
      "location": "PARAMETER_LOCATION_BODY", 
      "value": 30
    }
  ]
}

// Override for testing environment
{
  "selectedTools": [
    {
      "toolName": "processPayment",
      "parameterOverrides": {
        "environment": "sandbox", // Override static value
        "timeout": 10 // Shorter timeout for testing
      }
    }
  ]
}
​
Required Parameter Overrides
Some tools require certain parameters to be overridden at call creation time. This is common with built-in tools that need context-specific configuration.
​
Example: queryCorpus Tool
The built-in queryCorpus tool requires the corpus ID to be specified:
{
  "selectedTools": [
    {
      "toolName": "queryCorpus",
      "parameterOverrides": {
        "corpusId": "your-corpus-id-here" // Required override
      }
    }
  ]
}
​
Creating Tools with Required Overrides
{
  "name": "customerQuery",
  "definition": {
    "modelToolName": "customerQuery",
    "description": "Query customer database",
    "requirements": {
      "requiredParameterOverrides": ["databaseId"] // Must be overridden
    },
    "dynamicParameters": [
      {
        "name": "databaseId",
        "location": "PARAMETER_LOCATION_QUERY",
        "schema": { "type": "string" },
        "required": true
      },
      {
        "name": "searchTerm", 
        "location": "PARAMETER_LOCATION_BODY",
        "schema": { "type": "string" },
        "required": true
      }
    ]
  }
}

// Usage requires databaseId override
{
  "selectedTools": [
    {
      "toolName": "customerQuery",
      "parameterOverrides": {
        "databaseId": "prod-customers" // Required
        // searchTerm remains dynamic for the AI to set
      }
    }
  ]
}
​
Advanced Override Patterns
​
Multi-Environment Tool Configuration
// Base tool definition
{
  "name": "emailService",
  "definition": {
    "modelToolName": "sendEmail",
    "staticParameters": [
      {
        "name": "apiEndpoint",
        "location": "PARAMETER_LOCATION_HEADER",
        "value": "https://api.production-email.com"
      },
      {
        "name": "fromAddress",
        "location": "PARAMETER_LOCATION_BODY",
        "value": "noreply@production.com"
      }
    ]
  }
}

// Development environment override
const devEmailConfig = {
  "toolName": "emailService",
  "parameterOverrides": {
    "apiEndpoint": "https://api.dev-email.com",
    "fromAddress": "noreply@dev.com"
  }
};

// Staging environment override  
const stagingEmailConfig = {
  "toolName": "emailService",
  "parameterOverrides": {
    "apiEndpoint": "https://api.staging-email.com",
    "fromAddress": "noreply@staging.com"
  }
};
​
Feature-Specific Tool Variants
// Base search tool
{
  "name": "searchProducts",
  "dynamicParameters": [
    {
      "name": "query",
      "location": "PARAMETER_LOCATION_BODY",
      "schema": { "type": "string" },
      "required": true
    },
    {
      "name": "category",
      "location": "PARAMETER_LOCATION_BODY", 
      "schema": { "type": "string" },
      "required": false
    },
    {
      "name": "maxResults",
      "location": "PARAMETER_LOCATION_BODY",
      "schema": { "type": "integer" },
      "required": false
    }
  ]
}

// Electronics-focused agent
{
  "selectedTools": [
    {
      "toolName": "searchProducts",
      "nameOverride": "searchElectronics",
      "descriptionOverride": "Search for electronic products",
      "parameterOverrides": {
        "category": "electronics", // Lock to electronics
        "maxResults": 5 // Limit results
      }
    }
  ]
}

// Quick search variant
{
  "selectedTools": [
    {
      "toolName": "searchProducts", 
      "nameOverride": "quickSearch",
      "descriptionOverride": "Quick product search (top 3 results)",
      "parameterOverrides": {
        "maxResults": 3 // Quick results only
      }
    }
  ]
}
​
Authentication Context Overrides
// Multi-tenant tool
{
  "name": "databaseQuery",
  "staticParameters": [
    {
      "name": "tenantId",
      "location": "PARAMETER_LOCATION_HEADER",
      "value": "default"
    }
  ],
  "automaticParameters": [
    {
      "name": "authToken",
      "location": "PARAMETER_LOCATION_HEADER", 
      "knownValue": "KNOWN_PARAM_CALL_STATE"
    }
  ]
}

// Tenant-specific override
{
  "selectedTools": [
    {
      "toolName": "databaseQuery",
      "parameterOverrides": {
        "tenantId": "customer-abc-123"
      }
    }
  ]
}
​
Template Variables in Overrides
When using agents, parameter overrides can include template variables:
// Agent with template-based overrides
{
  "name": "Customer Service Agent",
  "callTemplate": {
    "selectedTools": [
      {
        "toolName": "customerLookup",
        "parameterOverrides": {
          "customerId": "{{customerId}}", // Template variable
          "region": "{{customerRegion}}"
        }
      }
    ]
  }
}

// Call creation with template context
{
  "templateContext": {
    "customerId": "cust-456789",
    "customerRegion": "us-west"
  }
}


