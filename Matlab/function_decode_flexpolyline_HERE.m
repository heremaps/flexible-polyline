% Decodes flexible polyline from HERE API 
% ------------------------------------------------------------------------------------------------------------
% Input: polyline (returned from HERE API)
% Output: struct
% ------------------------------------------------------------------------------------------------------------
% Reno Filla, NEPP, Scania R&D, created 2021-10-29, last updated 2021-10-29
% ------------------------------------------------------------------------------------------------------------


function out = function_decode_flexpolyline_HERE (polyline)       
% Documentation of how to encode a flexible polyline: https://github.com/heremaps/flexible-polyline

    out = struct;
    decoding_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    values = arrayfun(@(s) strfind(decoding_table,s)-1 , polyline);
    count = 1;
    decoded_raw = uint64(0);
    shift = 0;
    for i = 1:numel(polyline)
       decoded_raw = decoded_raw + bitshift(uint64(bitand(values(i),0x1F)),shift);   % mask out the lower 5 bits and adds if this is a continuation
%        display(['shift=',num2str(shift),',values(',num2str(i),')=',num2str(values(i)),'=',dec2bin(values(i)),'=>',dec2bin(uint64(bitand(values(i),0x1F))),'=>',dec2bin(bitshift(uint64(bitand(values(i),0x1F)),shift))])
%        display([num2str(decoded_raw),'=',dec2bin(decoded_raw)])
       if bitand(values(i),0x20)   % check for continuation
           shift = shift + 5;
       else
           decoded_uint(count) = double(decoded_raw);
           if bitand(decoded_raw, uint64(1))
               % negative number
               decoded_int(count) = -(double(decoded_raw) + 1)/2;
           else
               % positive number
               decoded_int(count) = double(decoded_raw) /2;               
           end
           if i <  numel(polyline) 
               count = count + 1;
               decoded_raw = uint64(0);
               shift = 0;    % reset shift
           end
       end
    end
    
    % decoding header version  (uint #1)
    out.header.version = decoded_uint(1);
    
    % decoding header content  (uint #2)
    out.header.precision = double(bitand(uint16(decoded_uint(2)), uint16(0b1111)));
    out.header.flag_3rd_dim = bitshift(bitand(uint16(decoded_uint(2)), uint16(0b1110000)),-4);   
    content_3rd_dim = {'absent','level','altitude','elevation','reserved1','reserved2','custom1','custom2'};
    out.header.content_3rd_dim = content_3rd_dim{out.header.flag_3rd_dim+1};       
    out.header.precision_3rd_dim = double(bitshift(bitand(uint16(decoded_uint(2)), uint16(0b1110000000)),-7));   

    % decoding data (starting with int #3)
    key_dims = {'latitude', 'longitude', content_3rd_dim{out.header.flag_3rd_dim+1}};
    precision_dims = [out.header.precision, out.header.precision, out.header.precision_3rd_dim];
    precision_dims(2,:) = 10.^precision_dims(1,:);
    if out.header.flag_3rd_dim == 0
        dims = 2;
    else
        dims = 3;
    end

    % decoding first tuple  (int #3-4 for 2D, int #3-5 if 3rd dimension present)
    for i=1:dims
        out.data.(key_dims{i})(1) = round(decoded_int(2+i)/precision_dims(2,i),precision_dims(1,i));
    end

    % decoding subsequent tuples  (starting with int #5 for 2D, int #6 if 3rd dimension present)
    for i=(2+dims):dims:numel(decoded_int)-1
        for j=1:dims
            out.data.(key_dims{j})((i-2)/dims+1) = round(decoded_int(i+j)/precision_dims(2,j) + out.data.(key_dims{j})((i-2)/dims),precision_dims(1,j));            
        end
    end

%     out.raw.decoded_uint = decoded_uint;
%     out.raw.decoded_int = decoded_int;
end
