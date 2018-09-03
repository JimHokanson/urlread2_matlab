classdef multipart_form_data < handle
    %
    %   Class:
    %   url2.multipart_form_data
    %
    %   https://tools.ietf.org/html/rfc7578
    
    
    %{
    -H  "accept: application/json" -H  "authorization: Bearer token" -H 
"Content-Type: multipart/form-data" -F "file=@Gax_EANs.csv;type="
    
    f = url2.multipart_form_data();
    f.addField('first_name','Bob')
    file_path = '/Users/jim/Desktop/simple_file.txt';
    f.addFile('hi_mom',file_path,'file_name','my_file.txt');
    
    [body,headers] = f.getBodyAndHeaders();
    
    
    %}
    
    properties
        boundary = '';
        fields = {}
    end
    
    properties (Dependent)
        field_names 
    end
    
    methods
        function obj = multipart_form_data(varargin)
            in.boundary  = '----WebKitFormBoundaryO1IKPYfMvDjoroRV';
            in = url2.sl.in.processVarargin(in,varargin);
            
            obj.boundary = in.boundary;
        end
        function addFile(obj,name,file_path,varargin)
            
            in.file_name = '';
            in = url2.sl.in.processVarargin(in,varargin);

            temp = url2.mpf_file_field(name,file_path,in.file_name);
            
            obj.fields{end+1} = temp;
            
        end
        function addField(obj,name,value)
            %https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition
            temp = url2.mpf_field(name,value);
            obj.fields{end+1} = temp;
        end
        function [body,headers] = getBodyAndHeaders(obj)
            body = '';
            for i = 1:length(obj.fields)
                temp = obj.fields{i};
                temp_body = temp.getBodyEntry(obj.boundary);
                body = [body temp_body]; %#ok<AGROW>
            end
            
            body = [body '--' obj.boundary '--'];
            
            headers = struct();
            headers.name = 'Content-Type';
            headers.value = sprintf('multipart/form-data; boundary=%s',obj.boundary);
        end
    end
    
end

%{

>> Host: httpbin.org
>> Connection: keep-alive
>> Content-Length: 304
>> User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 
>> (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36
>> Cache-Control: no-cache
>> Content-Type: multipart/form-data; 
>> boundary=----WebKitFormBoundaryO1IKPYfMvDjoroRV
>> Accept: */*
>> Accept-Encoding: gzip, deflate
>> Accept-Language: en-US,en;q=0.9
>> 
>> ------WebKitFormBoundaryO1IKPYfMvDjoroRV
>> Content-Disposition: form-data; name="Name"
>> 
>> Bob
>> ------WebKitFormBoundaryO1IKPYfMvDjoroRV
>> Content-Disposition: form-data; name="hi_mom"; filename="simple_file.txt"
>> Content-Type: text/plain
>> 
>> simple_file this is
>> ------WebKitFormBoundaryO1IKPYfMvDjoroRV--

%}