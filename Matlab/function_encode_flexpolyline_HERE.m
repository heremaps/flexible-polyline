% Encodes flexible polyline from HERE API
% ------------------------------------------------------------------------------------------------------------
% Input 1: matrix with either 2 columns containing (lat,lon) values or 3 columns containing (lat,lon,3rd_dim)
% Input 2: optional arguments: 'Precision': set precision of (lat,lon) values, default is 5
%                              'Flag_3rd_dim': set 3rd dimension by flag (see validContent_3rd_dim below)
%                              'Content_3rd_dim': set 3rd dimension by name (see validContent_3rd_dim below)
%                              'Precision_3rd_dim': set precision of 3rd dimension, default is 1
% Output: polyline (string)
% ------------------------------------------------------------------------------------------------------------
% Reno Filla, NEPP, Scania R&D, created 2021-11-13, last updated 2021-11-13
% ------------------------------------------------------------------------------------------------------------


function poly = function_encode_flexpolyline_HERE (LatLonData, varargin)       
% Documentation of how to encode a flexible polyline: https://github.com/heremaps/flexible-polyline

    validContent_3rd_dim = {'absent','level','altitude','elevation','reserved1','reserved2','custom1','custom2'};   % corresponding to Flag_3rd_dim = 0 to 7

    p = inputParser;
    defaultPrecision = 6;   
    defaultFlag_3rd_dim = 0;   
    defaultContent_3rd_dim = 'absent';
    defaultPrecision_3rd_dim = 1;   
    
    validationFcnPrecision = @(x) validateattributes(x,'numeric',{'scalar','nonnegative','integer'});
    validationFcnFlag = @(x) validateattributes(x,'numeric',{'scalar','integer','nonnegative','<=',7});
    validationFcnContent = @(x) validateattributes(x,'string','scalartext');
    
    addRequired(p,'LatLonData',@isnumeric);
    addOptional(p,'Precision',defaultPrecision,validationFcnPrecision);    
    addOptional(p,'Flag_3rd_dim',defaultFlag_3rd_dim,validationFcnFlag);    
    addOptional(p,'Content_3rd_dim',defaultContent_3rd_dim);    
    addOptional(p,'Precision_3rd_dim',defaultPrecision_3rd_dim,validationFcnPrecision);    

    p.KeepUnmatched = true;
    p.CaseSensitive = false;
    parse(p,LatLonData,varargin{:});

    if ~isnumeric (LatLonData)
        error ('The passed [lat,lon,3rd_dim] matrix must be numeric with 2 or 3 columns');
    else
        [num_rows, num_cols] = size(LatLonData);
        if or(num_cols<2,num_cols>3) 
            error ('The passed [lat,lon,3rd_dim] matrix must be numeric with 2 or 3 columns');
        end
    end

    Precision = p.Results.Precision;
    Precision_3rd_dim = p.Results.Precision_3rd_dim;
    Flag_3rd_dim = p.Results.Flag_3rd_dim;
    Content_3rd_dim = p.Results.Content_3rd_dim;

    if ~any(strcmp(p.UsingDefaults,'Content_3rd_dim'))    % if default value is not used for Content_3rd_dim, meaning that this option has been speficied
        validatestring(Content_3rd_dim,validContent_3rd_dim);   % let only valid Content values pass
        if ~any(strcmp(p.UsingDefaults,'Flag_3rd_dim'))    % if also the Flag_3rd_dim has been specified, which is in possible violation of Content_3rd_dim
            if ~strcmp(Content_3rd_dim, validContent_3rd_dim{Flag_3rd_dim})    % if contradicting specifications have been passed for Flag and Content
                error ('Contradicting values passed for "Flag_3rd_dim" and "Content_3rd_dim". (Sufficient to specify only one.)')
            end
        else
            Flag_3rd_dim = function_find_in_cell_array(validContent_3rd_dim,Content_3rd_dim)-1;    % set Flag according to Content
        end
    else     % default value is used for Content_3rd_dim, meaning that this option has not been speficied 
        if ~any(strcmp(p.UsingDefaults,'Flag_3rd_dim'))    % if the Flag_3rd_dim has been specified
            Content_3rd_dim = validContent_3rd_dim{Flag_3rd_dim+1};    % set Content according to Flag
        else
            if num_cols == 3
                error (['Value matrix has 3 columns yet no argument specifies the 3rd dimension. ' ...
                        'To ignore 3rd column set Flag_3rd_dim=0 or Content_3rd_dim=absent'])
            end
        end
    end
    
    if ~Flag_3rd_dim    % if 3rd dimension not present or to be ignored
        num_cols_to_process = 2;
        Precision_3rd_dim = 0;    % actually not necessary since we ignore the 3rd dimension anyway
    else
        if num_cols == 2
            error ('Value matrix has only 2 columns, thus lacking a 3rd dimension.')
        else
            num_cols_to_process = 3;            
        end
    end
         
    precision_dims = [Precision, Precision, Precision_3rd_dim];
    precision_dims(2,:) = 10.^precision_dims(1,:);

% ------------ START ------------
    encoding_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

    % header: version
    values(1) = 1;
    
    % header: content
    values(2) = Precision;      % bits 0-3: precision
    values(2) = bitor(values(2),bitshift(Flag_3rd_dim,4));  % bits 4-6: flag 3rd dimension
    values(2) = bitor(values(2),bitshift(Precision_3rd_dim,7));  % bits 7-10: precision of 3rd dimension
            
    for i=1:num_rows
        for j=1:num_cols_to_process
            if i==1
                values(2+num_cols_to_process*(i-1)+j) = int32(round(LatLonData(i,j)*precision_dims(2,j)));
            else
                values(2+num_cols_to_process*(i-1)+j) = int32(round(LatLonData(i,j)*precision_dims(2,j)))-int32(round(LatLonData(i-1,j)*precision_dims(2,j)));
            end
        end
    end
    
    poly = '';
    num_values = numel(values);
    for l=1:num_values
        if l<3
            poly_chunk = encode_uint(values(l),encoding_table);    % header to be encoded as unsigned integers
        else
            poly_chunk = encode_int(values(l),encoding_table);     % (lat,lon,3rd_dim) values to be encoded as signed integers
        end
        poly = [poly, poly_chunk];
    end
end


function index = function_find_in_cell_array (cell_array, string)
    index = NaN;
    sf = strfind(cell_array, string);    % creates cell array with results of strfind
    m = arrayfun (@(cell_array) ~isempty(cell2mat(cell_array)), sf);   % create matrix of true/false 
    [row, column] = ind2sub(size(m),find(m));    % find returns linear index, needs to be converted to matrix dimensions
    if ~isempty([row, column])
        index = column;
    end
end


function poly_chunk = encode_uint(value, encoding_table)
    value_str = dec2bin(value);
    value_len = numel(value_str);
    chunk = [];
    for k=1:5:value_len
        chunk(1+(k-1)/5) = bitand(bitshift(value,-(k-1)),int32(0x1F));
    end
    for k=1:numel(chunk)
        if k<numel(chunk)
            chunk(k) = bitor(chunk(k),int32(0x20));
        end
    end
    poly_chunk = encoding_table(chunk+1);    % (indices start with 1 in Matlab, not 0)
end


function poly_chunk = encode_int(value, encoding_table)
    if value < 0
        poly_chunk = encode_uint(2*abs(value)-1, encoding_table);
    else
        poly_chunk = encode_uint(2*value, encoding_table);
    end
end
