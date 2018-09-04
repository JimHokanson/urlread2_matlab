function [output,extras] = urlread2(url_char,method,body,headers_in,varargin)
%urlread2  Makes HTTP requests and processes response
%
%   [output,extras] = urlread2(url_char, *method, *body, *headers_in, varargin)
%
%   * indicates optional inputs that must be entered in place
%
%   UNDOCUMENTED MATLAB VERSION
%
%   EXAMPLE CALLING FORMS
%   ... = urlread2(urlChar)
%   ... = urlread2(urlChar,'GET','',[],prop1,value1,prop2,value2,etc)
%   ... = urlread2(urlChar,'POST',body,headers)
%   
%   Features
%   --------
%   1) Allows specification of any HTTP method
%   2) Allows specification of any header. Very little is hard-coded
%      in for header handling.
%   3) Returns response status and headers
%   4) Should handle unicode properly ...
%
%   Outputs
%   -------
%   output : body of the response, either text or binary depending upon
%            CAST_OUTPUT property
%   extras : (structure)
%       .allHeaders  - stucture, fields have cellstr values, HTTP headers may 
%           may be repeated but will have a single field entry, with each
%           repeat's value another being another entry in the cellstr, for
%           example:
%               .Set_Cookie = {'first_value' 'second_value'}
%       .firstHeaders - (structure), variable fields, contains the first
%                      string entry for each field in allHeaders, this
%                      structure can be used to avoid dereferencing a cell
%                      for fields you expect not to be repeated ...
%                   EXAMPLE:
%                   .Response       : 'HTTP/1.1 200 OK'}
%                   .Server         : 'nginx'
%                   .Date           : 'Tue, 29 Nov 2011 02:23:16 GMT'
%                   .Content_Type   : 'text/html; charset=UTF-8'
%                   .Content_Length : '109155'
%                   .Connection     : 'keep-alive'
%                   .Vary           : 'Accept-Encoding, User-Agent'
%                   .Cache_Control  : 'max-age=60, private'
%                   .Set_Cookie     : 'first_value'
%       .status     - (structure)
%               .value  : numeric value of status, ex. 200
%               .msg    : message that goes along with status, ex. 'OK'
%       .url        - eventual url that led to output, this can change from
%                     the input with redirects, see FOLLOW_REDIRECTS
%       .isGood     - (logical) I believe this is an indicator of the presence of 400
%                      or 500 status codes (see status.value) but more
%                      testing is needed. In other words, true if status.value < 400.
%                      In code, set true if the response was obtainable without 
%                      resorting to checking the error stream.
%
%   Inputs
%   ------
%   url_char : string
%       The full url, must include scheme (http, https)
%   method : string
%       Examples: 'GET' 'POST' etc
%   body : (vector)(char, uint8 or int8) 
%       Body to write, generally used with POST or PUT, use of uint8 or 
%       int8 ensures that the body input is not manipulated before sending, 
%       char is sent via unicode2native function with ENCODING input (see below)
%       ** Note this code automadically sets the content-length header
%          based on the input **
%   headers_in : (structure array)
%           Use [] or '' if no headers are needed
%       .name    - (string), name of the header, a name property is used
%                   instead of a field because the name must match a valid
%                   header
%       .value   - (string), value to use
%
%
%   Optional Inputs (varargin, property/value pairs)
%   -------------------------------------------------
%   cast_output : (default true) 
%       - true : Tries to convert output based on content type - this could
%                be improved ...
%       - false : output becomes a uint8 (byte) array
%   encoding : string or logical (default '')
%       If string, this is the input to unicode2native.
%       - '' : uses default for unicode2native
%       - false : just converts string to bytes, dropping high byte 
%   follow_redirects : logical (default true)
%       If false 3xx status codes will be returned and need to be handled
%       by the user, note this does not handle javascript or meta tag
%       redirects, just server based ones.
%   read_timeout : (default 0), 
%       - 0 means no timeout, value is in milliseconds
%
%
%   EXAMPLES
%   =======================================================================
%
%   GET:
%   --------------------------------------------
%   url    = 'http://www.mathworks.com/matlabcentral/fileexchange/';
%   query  = 'urlread2';
%   params = {'term' query};
%   queryString = http_paramsToString(params,1);
%   url = [url '?' queryString];
%   [output,extras] = urlread2(url);
%
%   POST:
%   --------------------------------------------
%   url    = 'http://posttestserver.com/post.php';
%   params = {'testChars' char([2500 30000]) 'new code' '?'};
%   [paramString,header] = http_paramsToString(params,1);
%   [output,extras] = urlread2(url,'POST',paramString,header);
%
%   From behind a firewall, use the Preferences to set your proxy server.
%
%   See Also:
%       http_paramsToString
%       unicode2native
%       native2unicode
%   
%   Based on original urlread code by Matthew J. Simoneau
%
%   VERSION = 1.2

in.cast_output      = true;
in.follow_redirects = true;
in.read_timeout     = 0;
in.encoding         = '';

in = url2.sl.in.processVarargin(in,varargin);

%Input handling
%---------------------------------------

if ~exist('method','var') || isempty(method), method = 'GET'; end
if ~exist('body','var'), body = ''; end
if ~exist('headersIn','var'), headers_in = []; end

assert(usejava('jvm'),'Function requires Java')

import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;
com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings %Proxy settings need to be set

%Create a urlConnection.
%-----------------------------------
urlConnection = getURLConnection(url_char);
%For HTTP uses sun.net.www.protocol.http.HttpURLConnection
%Might use ice.net.HttpURLConnection but this has more overhead

%SETTING PROPERTIES
%-------------------------------------------------------
urlConnection.setRequestMethod(upper(method));
urlConnection.setFollowRedirects(in.follow_redirects);
urlConnection.setReadTimeout(in.read_timeout);

if isobject(body)
   %JAH: TODO
   body_obj = body;
   [body,headers] = body_obj.getBodyAndHeaders();
   
end

for iHeader = 1:length(headers_in)
    curHeader = headers_in(iHeader);
    urlConnection.setRequestProperty(curHeader.name,curHeader.value);
end

if ~isempty(body)
    %Ensure row vector
    if size(body,1) > 1 %column_vector
        if size(body,2) > 1
            error('Input parameter to function: body, must be a vector')
        else
            %make a row vector
            body = body';
        end
    end

    if ischar(body)
        %NOTE: '' defaults to Matlab's default encoding scheme 
        if islogical(in.encoding)
            body = uint8(body);
        else
            body = unicode2native(body,in.encoding);
        end
    elseif ~(isa(body,'uint8') || isa(body,'int8'))
        error('Function input: body, should be of class char, uint8, or int8, detected: %s',class(body))
    end
    
    urlConnection.setRequestProperty('Content-Length',int2str(length(body)));
    urlConnection.setDoOutput(true);
    outputStream = urlConnection.getOutputStream;
    outputStream.write(body);
    outputStream.close;
else
    urlConnection.setRequestProperty('Content-Length','0');
end

%==========================================================================
%                   Read the data from the connection.
%==========================================================================
%This should be done first because it tells us if things are ok or not
%NOTE: If there is an error, functions below using urlConnection, notably
%getResponseCode, will fail as well
try
    inputStream = urlConnection.getInputStream;
    isGood = true;
catch ME
    isGood = false; 
%NOTE: HTTP error codes will throw an error here, we'll allow those for now
%We might also get another error in which case the inputStream will be
%undefined, those we will throw here
    inputStream = urlConnection.getErrorStream;
    
    if isempty(inputStream)
        msg = ME.message;
        I = strfind(msg,char([13 10 9])); %see example by setting timeout to 1
        %Should remove the barf of the stack, at ... at ... at ... etc
        %Likely that this could be improved ... (generate link with full msg)
        if ~isempty(I)
            msg = msg(1:I(1)-1);
        end
        fprintf(2,'Response stream is undefined\n below is a Java Error dump (truncated):\n');
        error(msg)
    end
end

%POPULATING HEADERS
%--------------------------------------------------------------------------
allHeaders = struct;
allHeaders.Response = {char(urlConnection.getHeaderField(0))};
done = false;
headerIndex = 0;

while ~done
    headerIndex = headerIndex + 1;
    headerValue = char(urlConnection.getHeaderField(headerIndex));
    if ~isempty(headerValue)
        headerName = char(urlConnection.getHeaderFieldKey(headerIndex));
        headerName = fixHeaderCasing(headerName); %NOT YET FINISHED
        
        %Important, for name safety all hyphens are replace with underscores
        headerName(headerName == '-') = '_';
        if isfield(allHeaders,headerName)
            allHeaders.(headerName) = [allHeaders.(headerName) headerValue];
        else
            allHeaders.(headerName) = {headerValue}; 
        end
    else
        done = true;
    end
end

firstHeaders = struct;
fn = fieldnames(allHeaders);
for iHeader = 1:length(fn)
   curField = fn{iHeader};
   firstHeaders.(curField) = allHeaders.(curField){1};
end

status = struct(...
    'value',    urlConnection.getResponseCode(),...
    'msg',      char(urlConnection.getResponseMessage));

%PROCESSING OF OUTPUT
%----------------------------------------------------------
byteArrayOutputStream = java.io.ByteArrayOutputStream;
% This StreamCopier is unsupported and may change at any time. OH GREAT :/
isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
isc.copyStream(inputStream,byteArrayOutputStream);
inputStream.close;
byteArrayOutputStream.close;     

if in.cast_output
    charset = '';
    
    %Extraction of character set from Content-Type header if possible
    if isfield(firstHeaders,'Content_Type')
        text = firstHeaders.Content_Type;
        %Always open to regexp improvements
        charset = regexp(text,'(?<=charset=)[^\s]*','match','once');
    end

    if ~isempty(charset)
        output = native2unicode(typecast(byteArrayOutputStream.toByteArray','uint8'),charset);
    else
        output = char(typecast(byteArrayOutputStream.toByteArray','uint8'));
    end
else
    %uint8 is more useful for later charecter conversions
    %uint8 or int8 is somewhat arbitary at this point
    output = typecast(byteArrayOutputStream.toByteArray','uint8');
end

extras              = struct;
extras.allHeaders   = allHeaders;
extras.firstHeaders = firstHeaders;
extras.status       = status;
%Gets eventual url even with redirection
extras.url          = char(urlConnection.getURL);
extras.isGood       = isGood;



end

function headerNameOut = fixHeaderCasing(headerName)
%fixHeaderCasing Forces standard casing of headers
%
%   headerNameOut = fixHeaderCasing(headerName)
%   
%   This is important for field access in a structure which
%   is case sensitive
%
%   Not yet finished. 
%   I've been adding to this function as problems come along
    
    switch lower(headerName)
        case 'location'
            headerNameOut = 'Location';
        case 'content_type'
            headerNameOut = 'Content_Type';
        otherwise
            headerNameOut = headerName;
    end
end

%==========================================================================
%==========================================================================
%==========================================================================

function urlConnection = getURLConnection(urlChar)
%getURLConnection
%
%   urlConnection = getURLConnection(urlChar)

% Determine the protocol (before the ":").
protocol = urlChar(1:find(urlChar==':',1)-1);


% Try to use the native handler, not the ice.* classes.
try
    switch protocol
        case 'http'
            %http://www.docjar.com/docs/api/sun/net/www/protocol/http/HttpURLConnection.html
            handler = sun.net.www.protocol.http.Handler;
        case 'https'
            handler = sun.net.www.protocol.https.Handler;
    end
catch ME
    handler = [];
end

% Create the URL object.
try
    if isempty(handler)
        url = java.net.URL(urlChar);
    else
        url = java.net.URL([],urlChar,handler);
    end
catch ME
    error('Failure to parse URL or protocol not supported for:\nURL: %s',urlChar);
end

% Get the proxy information using MathWorks facilities for unified proxy
% preference settings.
mwtcp = com.mathworks.net.transport.MWTransportClientPropertiesFactory.create();
proxy = mwtcp.getProxy();

% Open a connection to the URL.
if isempty(proxy)
    urlConnection = url.openConnection;
else
    urlConnection = url.openConnection(proxy);
end


end
