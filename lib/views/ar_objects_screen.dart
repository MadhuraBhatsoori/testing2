import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_fest/app_colors.dart';

class ARObjectsScreen extends StatefulWidget {
  const ARObjectsScreen({Key? key, required this.object, required this.isLocal})
      : super(key: key);
  final String object;
  final bool isLocal;

  @override
  State<ARObjectsScreen> createState() => _ARObjectsScreenState();
}

class _ARObjectsScreenState extends State<ARObjectsScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  ARNode? localObjectNode;
  ARNode? webObjectNode;
  bool isAdd = false;
  bool isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        isPermissionGranted = true;
      });
    } else if (status.isDenied) {
      // Request permission if not already granted
      var newStatus = await Permission.camera.request();
      if (newStatus.isGranted) {
        setState(() {
          isPermissionGranted = true;
        });
      } else {
        // Handle the case where permission is denied permanently
        setState(() {
          isPermissionGranted = false;
        });
      }
    } else {
      // Handle other cases like 'PermanentlyDenied' if needed
      setState(() {
        isPermissionGranted = false;
      });
    }
  }

  Future<void> _requestPermissionAgain() async {
    var newStatus = await Permission.camera.request();
    if (newStatus.isGranted) {
      setState(() {
        isPermissionGranted = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera permission is required for AR functionality."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: isPermissionGranted
          ? ARView(onARViewCreated: onARViewCreated)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Camera permission is required.'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _requestPermissionAgain,
                    child: Text('Grant Permission'),
                  ),
                ],
              ),
            ),
      floatingActionButton: isPermissionGranted
          ? FloatingActionButton(
              onPressed: widget.isLocal
                  ? onLocalObjectButtonPressed
                  : onWebObjectAtButtonPressed,
              child: Icon(isAdd ? Icons.remove : Icons.add),
            )
          : null,
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    // Initialize AR session only if permission is granted
    if (isPermissionGranted) {
      this.arSessionManager.onInitialize(
            showFeaturePoints: false,
            showPlanes: true,
            customPlaneTexturePath: "assets/triangle.png",
            showWorldOrigin: true,
            handleTaps: false,
          );
      this.arObjectManager.onInitialize();
    }
  }

  Future<void> onLocalObjectButtonPressed() async {
    if (localObjectNode != null) {
      arObjectManager.removeNode(localObjectNode!);
      localObjectNode = null;
    } else {
      var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: widget.object,
          scale: Vector3(0.2, 0.2, 0.2),
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0));
      bool? didAddLocalNode = await arObjectManager.addNode(newNode);
      localObjectNode = (didAddLocalNode!) ? newNode : null;
    }
  }

  Future<void> onWebObjectAtButtonPressed() async {
    setState(() {
      isAdd = !isAdd;
    });

    if (webObjectNode != null) {
      arObjectManager.removeNode(webObjectNode!);
      webObjectNode = null;
    } else {
      var newNode = ARNode(
          type: NodeType.webGLB,
          uri: widget.object,
          scale: Vector3(0.2, 0.2, 0.2));
      bool? didAddWebNode = await arObjectManager.addNode(newNode);
      webObjectNode = (didAddWebNode!) ? newNode : null;
    }
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }
}
