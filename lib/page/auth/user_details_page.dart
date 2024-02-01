import 'package:flutter/material.dart';

class UserDetailsPage extends StatelessWidget {
  const UserDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CREATE ACCOUNT"),
      ),
      body: LayoutBuilder(
        builder: ((context, constraints) {
          // double width = constraints.maxWidth;
          // double height = constraints.maxHeight;

          return SingleChildScrollView(
            child: Column(
              children: [
                // NAME
                TextFormField(
                    // controller: nameController,
                    ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
