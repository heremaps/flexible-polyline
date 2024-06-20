namespace FlexiblePolylineEncoder
{
    /// <summary>
    /// 3rd dimension specification.
    /// Example a level, altitude, elevation or some other custom value.
    /// ABSENT is default when there is no third dimension en/decoding required.
    /// </summary>
    public enum ThirdDimension
    {
        Absent = 0,
        Level = 1,
        Altitude = 2,
        Elevation = 3,
        Reserved1 = 4,
        Reserved2 = 5,
        Custom1 = 6,
        Custom2 = 7
    }
}
