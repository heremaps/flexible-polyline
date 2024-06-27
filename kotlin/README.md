# Quick compilation and testing instructions
```bash
$ kotlinc "./src/com/here/flexiblepolyline/FlexiblePolyline.kt" "./src/com/here/flexiblepolyline/FlexiblePolylineTest.kt" -include-runtime -d FlexiblePolylineText.jar
```
to run the performance test with the default polyline length of 1000 vertices, or
```bash
$ java -jar FlexiblePolylineText.jar $POLYLINE_LENGTH
```
to use `$POLYLINE_LENGTH` vertices for the performance test.