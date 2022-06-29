using System;

namespace HERE.FlexiblePolyline
{
    /// <summary>
    /// Coordinate triple
    /// </summary>
    public class LatLngZ
    {
        public double Lat { get; }
        public double Lng { get; }
        public double Z { get; }

        public LatLngZ(double latitude, double longitude, double thirdDimension = 0)
        {
            Lat = latitude;
            Lng = longitude;
            Z = thirdDimension;
        }

        public override string ToString()
        {
            return "LatLngZ [lat=" + Lat + ", lng=" + Lng + ", z=" + Z + "]";
        }

        public override bool Equals(object obj)
        {
            if (this == obj)
            {
                return true;
            }

            if (obj is LatLngZ latLngZ)
            {
                if (latLngZ.Lat == Lat && latLngZ.Lng == Lng && latLngZ.Z == Z)
                {
                    return true;
                }
            }

            return false;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(Lat, Lng, Z);
        }
    }
}
