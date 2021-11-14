% test variables
encoded_1 = 'BFoz5xJ67i1B1B7PzIhaxL7Y';
decoded_1 = struct;
decoded_1.header.version = 1;
decoded_1.header.precision = 5;
decoded_1.header.flag_3rd_dim = 0;
decoded_1.header.content_3rd_dim = 'absent';
decoded_1.header.precision_3rd_dim = 0;
decoded_1.data.latitude = [50.10228,50.10201,50.10063,50.09878];
decoded_1.data.longitude = [8.69821,8.69567,8.6915,8.68752];

encoded_2 = 'BlBoz5xJ67i1BU1B7PUzIhaUxL7YU';
decoded_2 = struct;
decoded_2.header.version = 1;
decoded_2.header.precision = 5;
decoded_2.header.flag_3rd_dim = 2;
decoded_2.header.content_3rd_dim = 'altitude';
decoded_2.header.precision_3rd_dim = 0;
decoded_2.data.latitude = [50.10228,50.10201,50.10063,50.09878];
decoded_2.data.longitude = [8.69821,8.69567,8.6915,8.68752];
decoded_2.data.altitude = [10,20,30,40];


% test preconditions
test = function_encode_flexpolyline_HERE([decoded_1.data.latitude',decoded_1.data.longitude'],'Precision',decoded_1.header.precision);
assert(ischar(test),'Output must be a char')

%% Test 1: 2D (only latitude and longitude)
test = function_encode_flexpolyline_HERE([decoded_1.data.latitude',decoded_1.data.longitude'],'Precision',decoded_1.header.precision);
assert(isequal(test, encoded_1),'Failed 2D case')

%% Test 2: 3D (altitude as 3rd dimension)
test = function_encode_flexpolyline_HERE([decoded_2.data.latitude',decoded_2.data.longitude',decoded_2.data.altitude'], ...
            'Precision',decoded_2.header.precision, 'Flag_3rd_dim', decoded_2.header.flag_3rd_dim, 'Precision_3rd_dim', decoded_2.header.precision_3rd_dim);
assert(isequal(test, encoded_2),'Failed 3D case')

