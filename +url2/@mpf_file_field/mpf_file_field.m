classdef mpf_file_field < handle
    %
    %   Class:
    %   url2.mpf_file_field
    
    properties
        name
        file_path
        file_name
        content_type
    end
    
    methods
        function obj = mpf_file_field(name,file_path,varargin)
            %
            %   obj = url2.mpf_file_field(name,file_path,varargin)
            %
            %   Optional Inputs
            %   ---------------
            %   file_name :
            %   content_type : 
            %
            %   See Also
            %   --------
            %   url2.multipart_form_data
            
            in.file_name = '';
            in.content_type = '';
            in = url2.sl.in.processVarargin(in,varargin);
            
            
            obj.name = name;
            %TODO: Check file existence ...
            obj.file_path = file_path;
            obj.file_name = in.file_name;
            obj.content_type = in.content_type;
        end
       	function output = getBodyEntry(obj,boundary)
            crlf = char([13 10]);
%             >> Content-Disposition: form-data; name="hi_mom"; filename="simple_file.txt"
% >> Content-Type: text/plain
            %TODO: This needs to be fixed ...
            str1 = sprintf('--%s%s',boundary,crlf);
            str2 = sprintf('Content-Disposition: form-data; name="%s";',obj.name);
            if ~isempty(obj.file_name)
                str2 = sprintf('%s filename="%s"%s',str2,obj.file_name,crlf);
            else
                str2 = sprintf('%s%s',str2,crlf);
            end
            if ~isempty(obj.content_type)
                str2 = sprintf('%sContent-Type: %s%s',str2,obj.content_type,crlf);                
            end
            
            lead_in_bytes = uint8([str1 str2 crlf]);
            
            [fid, msg] = fopen(obj.file_path);
            if fid == -1
                error(message('MATLAB:fileread:cannotOpenFile', obj.file_path, msg));
            end

            try
                value_bytes = fread(fid,'*uint8')';
            catch exception
                fclose(fid);
                throw(exception);
            end

            fclose(fid);
            
            output = [lead_in_bytes value_bytes uint8(crlf)];
            
        end
    end
    
end

