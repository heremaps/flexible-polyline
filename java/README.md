# Quick compilation and testing instructions
```bash
$ javac  -d out src/com/here/flexpolyline/PolylineEncoderDecoder*.java
$ java -cp out com.here.flexpolyline.PolylineEncoderDecoderTest
```
to run the performance test with the default polyline length of 1000 vertices, or
```bash
$ java -cp out com.here.flexpolyline.PolylineEncoderDecoderTest $POLYLINE_LENGTH
```
to use `$POLYLINE_LENGTH` vertices for the performance test.