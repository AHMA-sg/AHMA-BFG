location of unity ios project: /Users/abhishek/LocalProjects/ahma/ios-build
contains xcode project inside

it is the home page of my app with one button with a simple script, I need to unload it when not on home page.

script:

'''
using UnityEngine;
using System.Runtime.InteropServices;

public class SpriteToggleTouch : MonoBehaviour
{
    public Sprite spriteA;
    public Sprite spriteB;

    private SpriteRenderer sr;
    private bool isPressed = false;

#if UNITY_IOS
    // On iOS plugins are statically linked into the executable, 
    // so we have to use __Internal as the library name.
    [DllImport("__Internal")]
    // This function is defined in flutter_embed_unity_2022_3_ios/ios/Classes/SendToFlutter.swift
    private static extern void FlutterEmbedUnityIos_sendToFlutter(string data);
#endif

    void Start()
    {
        sr = GetComponent<SpriteRenderer>();
        sr.sprite = spriteA;
    }

    void Update()
    {   
        #if UNITY_EDITOR
        if(Input.GetMouseButtonDown(0))
        {
            Debug.Log("yay");
            isPressed = true;
            sr.sprite = spriteB;
            Debug.Log("pressed");

        }
        else if (Input.GetMouseButtonUp(0))
        {
            if(isPressed)
            {
                isPressed = false;
                sr.sprite = spriteA;
                SendToFlutter("touch_released");
            }
        }
        #endif
        
        if (Input.touchCount > 0)
        {
            Touch t = Input.GetTouch(0);

            if (t.phase == TouchPhase.Began)
            {
                if (IsTouchingThisSprite(t.position))
                {
                    isPressed = true;
                    sr.sprite = spriteB;
                }
            }
            else if (t.phase == TouchPhase.Ended || t.phase == TouchPhase.Canceled)
            {
                if (isPressed)
                {
                    isPressed = false;
                    sr.sprite = spriteA;
                    SendToFlutter("touch_released");
                }
            }
        }
    }

    bool IsTouchingThisSprite(Vector2 screenPos)
    {
        Ray ray = Camera.main.ScreenPointToRay(screenPos);
        RaycastHit hit;

        if (Physics.Raycast(ray, out hit))
        {
            Debug.Log("hit: " + hit.collider.name);
            return hit.collider.gameObject == gameObject;
        }
        else
        {
            Debug.Log("didnt work");
        }
        return false;
    }

    void SendToFlutter(string message)
    {
        #if UNITY_IOS && !UNITY_EDITOR
            FlutterEmbedUnityIos_sendToFlutter(message);
        #else
            Debug.Log("Flutter Message: " + message);
        #endif
    }
}
'''
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: EmbedUnity(
              onMessageFromUnity: (String message) {
                // Receive message from Unity
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Send message to Unity
              sendToUnity(
                "MyGameObject",  // Game object name
                "SetRotationSpeed",  // Unity script function name
                "42",  // Message
              );
            },
            child: const Text("Set rotation speed"),
          )
        ],
      ),
    ),
  ));
}

public class MyGameObjectScript : MonoBehaviour
{
    void Update()
    {
        if (Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Began)
        {
             // Send message to Flutter:
             SendToFlutter.Send("touch");
        }
    }

    // Called from Flutter:
    public void SetRotationSpeed(string message)
    {
        // Do something with message
    }
}




project containing:

- UnityFramework.framework
- Data folder
- Classes folder
- Libraries folder

### **2. Drag Unity Xcode project INTO your Flutter iOS project**

Inside:

```
your_flutter/ios/Runner/
```

### **3. Modify Podfile**

Add the Unity integration pod.

### **4. Modify AppDelegate.swift**

You must add:

- UnityAppController
- UnityMessageHandler
- UnityFramework load code

### **5. Use `UnityWidget()` in Flutter**

---

# 📝 **In summary for iOS**

❌ You cannot build Unity normally

❌ You cannot just “export IPA”

✔ You MUST integrate UnityFramework into Flutter’s Xcode project


# **What should YOU do? (best answer for your use case)**

✔ Unity toggles → send message to Flutter

✔ Flutter navigates to Menu

✔ Immediately call:

_unityController?.unload();

Unity is completely gone → **0% CPU usage**.

When you need the Unity screen again, reload it:

Dart

_unityController?.create();

# **STEP 1 — Install the Flutter Unity Widget**

This is currently the most stable way to run Unity inside Flutter.

From `pubspec.yaml`:

dependencies:
flutter_unity_widget: ^2024.0.1

flutter pub get

```cpp
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UnityWidgetController? _unityController;

  void onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
  }

  void onUnityMessage(dynamic message) {
    print("Unity says: $message");

    if (message == "touch_released") {
      // When the toggle is released, switch pages
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MenuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UnityWidget(
        onUnityCreated: onUnityCreated,
        onUnityMessage: onUnityMessage,
      ),
    );
  }
}
```

void onUnityMessage(message) {
print("Unity says: $message");
}

Unity says: touch_released

UnityWidget(
onUnityCreated: (controller) {
this.controller = controller;
},
onUnityMessage: onUnityMessage,
);