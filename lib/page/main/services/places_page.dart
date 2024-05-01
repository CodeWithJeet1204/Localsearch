// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class PlacesPage extends StatefulWidget {
//   const PlacesPage({
//     super.key,
//     required this.place,
//   });

//   final String place;

//   @override
//   State<PlacesPage> createState() => _PlacesPageState();
// }

// class _PlacesPageState extends State<PlacesPage> {
//   final store = FirebaseFirestore.instance;
//   Map<String, dynamic> serviceman = {};
//   bool isData = false;

//   // INIT STATE
//   @override
//   void initState() {
//     getIdData();
//     super.initState();
//   }

//   // GET ID DATA
//   Future<void> getIdData() async {
//     List myIds = [];
//     final serviceSnap = await store.collection('Services').get();

//     serviceSnap.docs.forEach((service) {
//       final serviceData = service.data();

//       final String id = service.id;
//       final List places = serviceData['Place'];

//       if (places.contains(widget.place)) {
//         myIds.add(id);
//       }
//     });

//     await getServicemanData(myIds);
//   }

//   // GET SERVICEMAN DATA
//   Future<void> getServicemanData(List placesId) async {
//     Map<String, dynamic> myServiceman = {};
//     placesId.forEach((id) async {
//       final servicemanSnap = await store.collection('Services').doc(id).get();

//       final servicemanData = servicemanSnap.data()!;

//       final name = servicemanData['Name'];
//       final imageUrl = servicemanData['Image'];

//       myServiceman[id] = [name, imageUrl];
//     });

//     setState(() {
//       serviceman = myServiceman;
//       isData = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.place),
//       ),
//       body: !isData
//           ? Center(
//               child: CircularProgressIndicator(),
//             )
//           : SafeArea(
//               child: Padding(
//                 padding: EdgeInsets.all(
//                   MediaQuery.of(context).size.width * 0.006125,
//                 ),
//                 child: SizedBox(
//                   width: MediaQuery.of(context).size.width,
//                   child: ListView.builder(
//                     shrinkWrap: true,
//                     physics: ClampingScrollPhysics(),
//                     // itemCount: ,
//                     itemBuilder: ((context, index) {
//                       return ListTile();
//                     }),
//                   ),
//                 ),
//               ),
//             ),
//     );
//   }
// }
