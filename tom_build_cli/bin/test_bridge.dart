import 'package:tom_build_cli/tom_build_cli.dart';

void main() async {
  print('Testing VS Code Bridge Client...');
  
  final client = VSCodeBridgeClient();
  print('Connecting to port ${client.port}...');
  
  if (await client.connect()) {
    print('Connected!');
    
    // Test 1: Simple expression
    print('\n=== Test 1: Simple expression 1+2 ===');
    var result = await client.executeExpression('1+2');
    print('Success: ${result.success}, Value: ${result.value}');
    if (!result.success) print('Error: ${result.error}');
    
    // Test 2: Access VSCode.vsCode
    print('\n=== Test 2: Access VSCode.vsCode ===');
    result = await client.executeExpression('VSCode.vsCode');
    print('Success: ${result.success}, Value: ${result.value}');
    if (!result.success) print('Error: ${result.error}');
    
    // Test 3: Access vscode global
    print('\n=== Test 3: Access vscode global ===');
    result = await client.executeExpression('vscode');
    print('Success: ${result.success}, Value: ${result.value}');
    if (!result.success) print('Error: ${result.error}');
    
    // Test 4: Access window global
    print('\n=== Test 4: Access window global ===');
    result = await client.executeExpression('window');
    print('Success: ${result.success}, Value: ${result.value}');
    if (!result.success) print('Error: ${result.error}');
    
    // Test 5: Call vscode.window.showInformationMessage
    print('\n=== Test 5: Show info message ===');
    result = await client.executeExpression("vscode.window.showInformationMessage('Hello from CLI!')");
    print('Success: ${result.success}, Value: ${result.value}');
    if (!result.success) print('Error: ${result.error}');
    
    print('\n--- Test Complete ---');
    

    print('Make sure the CLI integration server is running in VS Code.');
    print('(Use Command Palette: "DS: Start Tom CLI Integration Server")');
  }
}
