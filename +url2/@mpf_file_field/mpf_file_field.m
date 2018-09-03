classdef mpf_file_field < handle
    %
    %   Class:
    %   url2.mpf_file_field
    
    properties
        name
        file_path
        file_name
    end
    
    methods
        function obj = mpf_file_field(name,file_path,file_name)
            %
            %   obj = url2.mpf_file_field(name,file_path,file_name)
            
            obj.name = name;
            %TODO: Check file existence ...
            obj.file_path = file_path;
            obj.file_name = file_name;
        end
       	function str = getBodyEntry(obj,boundary)
            crlf = char([13 10]);
%             >> Content-Disposition: form-data; name="hi_mom"; filename="simple_file.txt"
% >> Content-Type: text/plain
            %TODO: This needs to be fixed ...
            str1 = sprintf('--%s%s%s',boundary,crlf,crlf);
            value_string = fileread(obj.file_path);
            str = sprintf('%s%s%s',str1,value_string,crlf);
        end
    end
    
end

