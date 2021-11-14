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
test_2_decoded = function_decode_flexpolyline_HERE(encoded_2);
assert(isstruct(test_2_decoded),'Output must be a struct')
assert(isfield(test_2_decoded,'header'),'Output must include header field')
assert(isstruct(test_2_decoded.header),'Header field must be a struct')
assert(isfield(test_2_decoded.header,'version'),'Header field must have version field')
assert(isnumeric(test_2_decoded.header.version),'Version field in header must be numeric')
assert(isfield(test_2_decoded.header,'precision'),'Header field must have precision field')
assert(isnumeric(test_2_decoded.header.precision),'Precision field in header must be numeric')
assert(isfield(test_2_decoded.header,'flag_3rd_dim'),'Header field must have flag_3rd_dim field')
assert(isnumeric(test_2_decoded.header.flag_3rd_dim),'Flag_3rd_dim field in header must be numeric')
assert(isfield(test_2_decoded.header,'content_3rd_dim'),'Header field must have content_3rd_dim field')
assert(ischar(test_2_decoded.header.content_3rd_dim),'Content_3rd_dim field in header must be a char')
assert(isfield(test_2_decoded.header,'precision_3rd_dim'),'Header field must have precision_3rd_dim field')
assert(isnumeric(test_2_decoded.header.precision_3rd_dim),'Precision_3rd_dim field in header must be numeric')
assert(isfield(test_2_decoded,'data'),'Output must include data field')
assert(isstruct(test_2_decoded.data),'Data field must be a struct')
assert(isfield(test_2_decoded.data,'latitude'),'Data field must have latitude field')
assert(isnumeric(test_2_decoded.data.latitude),'Latitude field in data must be numeric')
assert(isfield(test_2_decoded.data,'longitude'),'Data field must have longitude field')
assert(isnumeric(test_2_decoded.data.longitude),'Longitude field in data must be numeric')
assert(isfield(test_2_decoded.data,'altitude'),'Data field must have 3rd dimension field, e.g. altitude')
assert(isnumeric(test_2_decoded.data.altitude),'3rd dimension field in data, e.g. altitude, must be numeric')

%% Test 1: 2D (only latitude and longitude)
test = function_decode_flexpolyline_HERE(encoded_1);
assert(isequal(test, decoded_1),'Failed 2D case')

%% Test 2: 3D (altitude as 3rd dimension)
test = function_decode_flexpolyline_HERE(encoded_2);
assert(isequal(test, decoded_2),'Failed 3D case')

