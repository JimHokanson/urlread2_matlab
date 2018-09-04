classdef multipart_form_data < handle
    %
    %   Class:
    %   url2.multipart_form_data
    %
    %   https://tools.ietf.org/html/rfc7578
    
    
    %{

    form = url2.multipart_form_data();
    form.addField('first_name','Bob')
    file_path = '/Users/jim/Desktop/simple_file.txt';
    form.addFile('hi_mom',file_path,'file_name','my_file.txt');
    
    url = 'https://postman-echo.com/post';
    [output,extras] = urlread2(url, 'post', form)
        
    %This just basically shows how postman interpreted the call
    temp = jsondecode(output);
    
    
    %For internal debugging - don't call
    [body,headers] = form.getBodyAndHeaders();
    
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
            %X Add file to the form
            %
            %   addFile(obj,name,file_path,varargin)
            %
            %   Optional Inputs
            %   ---------------
            %   file_name : string
            %       Name of the file for the server.
            %   content_type : string
            %       Example 'text/plain' (text) or 'application/octet-stream' (binary
            
            in.file_name = '';
            in.content_type = '';
            in = url2.sl.in.processVarargin(in,varargin);

            temp = url2.mpf_file_field(name,file_path,in);
            
            obj.fields{end+1} = temp;
            
        end
        function addField(obj,name,value)
            %https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition
            temp = url2.mpf_field(name,value);
            obj.fields{end+1} = temp;
        end
        function [body,headers] = getBodyAndHeaders(obj)
            body = uint8([]);
            for i = 1:length(obj.fields)
                temp = obj.fields{i};
                temp_body = temp.getBodyEntry(obj.boundary);
                body = [body temp_body]; %#ok<AGROW>
            end
            
            end_str = ['--' obj.boundary '--'];
            body = [body uint8(end_str)];
            
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