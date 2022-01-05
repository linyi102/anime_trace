// import 'package:flutter/material.dart';

// class NoteCard extends StatelessWidget {
//   const NoteCard({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
//       child: _episodeNotes[i].imgLocalPaths.isEmpty &&
//               _episodeNotes[i].noteContent.isEmpty
//           ? Container()
//           : Card(
//               elevation: 0,
//               child: MaterialButton(
//                 onPressed: () {
//                   Navigator.of(context)
//                       .push(MaterialPageRoute(
//                           builder: (context) =>
//                               EpisodeNoteSF(_episodeNotes[i])))
//                       .then((value) {
//                     _episodeNotes[i] = value; // 更新修改
//                     setState(() {});
//                   });
//                 },
//                 child: Column(
//                   children: [
//                     _episodeNotes[i].noteContent.isEmpty
//                         ? Container()
//                         : ListTile(
//                             title: Text(_episodeNotes[i].noteContent),
//                           ),
//                     showImageGridView(_episodeNotes[i].imgLocalPaths.length,
//                         (BuildContext context, int index) {
//                       return ImageGridItem(
//                           _episodeNotes[i].imgLocalPaths[index]);
//                     })
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }
