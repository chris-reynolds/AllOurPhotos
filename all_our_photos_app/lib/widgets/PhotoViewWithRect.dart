/*
  Created by chrisreynolds on 2019-09-11

  Purpose:

*/

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';



class PhotoViewerWithRect extends StatelessWidget {
  final PhotoViewController pvc = PhotoViewController();
  final String url;

  PhotoViewerWithRect({@required GlobalKey key,@required this.url}):super(key:key) ; // of constructor

  Rect currentRect(Size pictureSize) {
    // if there is no scale yet, assume the whole photo is showing
    if (pvc.scale == null)
      return Rect.fromLTWH(0, 0, pictureSize.width, pictureSize.height);
    Offset centrePoint = pvc.position;
    double scale = pvc.scale;
    RenderBox renderBox = (this.key as GlobalKey).currentContext.findRenderObject();
    Size widgetSize = renderBox?.size;
    double leftEdge = (centrePoint.dx+0.5*widgetSize.width)/scale+pictureSize.width/2;
    double rightEdge = (centrePoint.dx-0.5*widgetSize.width)/scale+pictureSize.width/2;
    double topEdge = -(centrePoint.dy+0.5*widgetSize.height)/scale+pictureSize.height/2;
    double bottomEdge = -(centrePoint.dy-0.5*widgetSize.height)/scale+pictureSize.height/2;
    // ensure inbounds if zoomed out
    if (leftEdge>pictureSize.width) leftEdge = pictureSize.width;
    if (rightEdge<0) rightEdge = 0;
    if (topEdge<0) topEdge = 0;
    if (bottomEdge>pictureSize.height) bottomEdge = pictureSize.height;
    print('centre $centrePoint scale $scale  picture $pictureSize \nfrom ($rightEdge,$topEdge) to ($leftEdge,$bottomEdge)');
    return Rect.fromLTRB(leftEdge, topEdge, rightEdge, bottomEdge);
  } // of currentRect

  @override
  Widget build(BuildContext context) {
    print('Building photoViewerWithRect');
    return PhotoView(
      imageProvider: NetworkImage(url),
      controller: pvc,
    );
  } // of build
} // of PhotoViewerWithRect


