import 'package:flutter/material.dart';

import '../../models/sameday_ooh_location.dart';
import '../../widgets/sameday/easybox_map.dart';

class EasyboxPickerPage
    extends StatefulWidget {
  final SamedayOohLocation?
      initialSelection;

  const EasyboxPickerPage({
    super.key,
    this.initialSelection,
  });

  @override
  State<EasyboxPickerPage>
      createState() =>
          _EasyboxPickerPageState();
}

class _EasyboxPickerPageState
    extends State<EasyboxPickerPage> {
  SamedayOohLocation? _selected;

  @override
  void initState() {
    super.initState();

    _selected =
        widget.initialSelection;
  }

  // ==========================================================
  // SELECT
  // ==========================================================

  void _selectEasybox(
    SamedayOohLocation location,
  ) {
    setState(() {
      _selected = location;
    });

    Navigator.of(context).pop(
      location,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF8FAFC,
      ),

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.transparent,

        elevation: 0,

        title:
            const Text(
          'Alege Easybox',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        leading:
            IconButton(
          onPressed: () {
            Navigator.of(context)
                .pop();
          },
          icon:
              const Icon(
            Icons.arrow_back,
          ),
        ),
      ),

      body: Column(
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets
                    .fromLTRB(
              16,
              14,
              16,
              14,
            ),

            color:
                Colors.white,

            child:
                const Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Icon(
                  Icons
                      .location_on_outlined,
                  color:
                      Color(
                    0xFF4F46E5,
                  ),
                ),

                SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Alege locația de livrare',
                        style:
                            TextStyle(
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),

                      SizedBox(
                        height: 3,
                      ),

                      Text(
                        'Selectează Easybox-ul în care vrei să primești coletul.',
                        style:
                            TextStyle(
                          fontSize:
                              13,
                          color:
                              Color(
                            0xFF64748B,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          // ==================================================
          // MAP
          // ==================================================

          Expanded(
            child:
                EasyboxMap(
              initialSelection:
                  _selected,

              onSelected:
                  _selectEasybox,
            ),
          ),
        ],
      ),
    );
  }
}