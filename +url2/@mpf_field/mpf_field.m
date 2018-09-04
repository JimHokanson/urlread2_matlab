classdef mpf_field < handle
    %
    %   Class:
    %   url2.mpf_field
    %
    %   mpf => multipart-form
    %
    %   https://tools.ietf.org/html/rfc7578#section-4.1
    %
    %   See Also
    %   --------
    %   url2.multipart_form_data
    
    
    %{
    The multipart/form-data media type does not support any MIME header
   fields in parts other than Content-Type, Content-Disposition, and (in
   limited circumstances) Content-Transfer-Encoding.  Other header
   fields MUST NOT be included and MUST be ignored.

    content-disposition: form-data; name="field1"
       content-type: text/plain;charset=UTF-8
       content-transfer-encoding: quoted-printable

       Joe owes =E2=82=AC100.
    
    Each part MUST contain a Content-Disposition header field [RFC2183]
   where the disposition type is "form-data".  The Content-Disposition
   header field MUST also contain an additional parameter of "name"; the
   value of the "name" parameter is the original field name from the
   form (possibly encoded; see Section 5.1).  For example, a part might
   contain a header field such as the following, with the body of the
   part containing the form data of the "user" field:

           Content-Disposition: form-data; name="user"

   For form data that represents the content of a file, a name for the
   file SHOULD be supplied as well, by using a "filename" parameter of
   the Content-Disposition header field.  The file name isn't mandatory
   for cases where the file name isn't available or is meaningless or
   private; this might result, for example, when selection or drag-and-
   drop is used or when the form data content is streamed directly from
   a device.

    The encoding used for the file names is typically UTF-8, although
   HTML forms will use the charset associated with the form.
    
    
    %}
    
    
%     --AaB03x
%    Content-Disposition: form-data; name="submit-name"
% 
%    Larry
%    --AaB03x
%    Content-Disposition: form-data; name="files"
%    Content-Type: multipart/mixed; boundary=BbC04y
% 
%    --BbC04y
%    Content-Disposition: file; filename="file1.txt"
%    Content-Type: text/plain
% 
%    ... contents of file1.txt ...
%    --BbC04y
%    Content-Disposition: file; filename="file2.gif"
%    Content-Type: image/gif
%    Content-Transfer-Encoding: binary
% 
%    ...contents of file2.gif...
%    --BbC04y--
%    --AaB03x--
    
    
    properties
        name
        value
    end
    
    methods
        function obj = mpf_field(name,value)
            obj.name = name;
            obj.value = value;
        end
        function str = getBodyEntry(obj,boundary)
            crlf = char([13 10]);
            str1 = sprintf('--%s%sContent-Disposition: form-data; name="%s"%s',...
                boundary,crlf,obj.name,crlf);
            if isnumeric(obj.value)
                value_string = sprintf('%g',obj.value);
            elseif ischar(obj.value)
                value_string = obj.value;
            else
                error('Unhandled case')
            end
            
            str = [str1 crlf value_string crlf];
            
            %This could be improved (done earlier)
            str = uint8(str);
        end
    end
    
end

