function target = ssParseMagically(parser, target, varargin)
% parse() the given inputParser and assign results to the given target.
%
% The idea here is that I like the Matlab inputParser but using it requires
% A lot of redundant typing.  The worst part is taking values out of the
% parser's Results field and assigning them in the releant workspace or
% object.  Since the variable names and values are all known to the parser
% already, it should be able to do this work for us.  That's what this
% function does.
%
% target = ssParseMagically(parser, target, varargin) invokes parse() on
% the given input parser.  Then for each field of the parser's Results
% field, assigns the named value to the given target.  If the target is a
% struct or object, assigns to fields of target and returns the updated
% target.  If the target is a string, uses Matlab's magical assignin()
% function to assign the named value in the target workspace ('caller' or
% 'base').
%
% Here's an example of code for a calling function:
%
%   parser = inputParser();
%   parser.addRequired('name', @ischar);
%   parser.addParameter('height', 1.8, @isnumeric);
%   ssParseMagically(parser, 'caller', name, varargin{:});
%   disp(height);
%
% Fun note: this is a really short function to save a lot of work.  In
% fact, if the parser has about 10 or more degfined arguments, the code in
% this funciton is less than the code you'd have to write to dig out all
% the Results explicitly!
%
% 2016 isetbio team

%% Do parsing like always.
parser.parse(varargin{:});

%% Use magic to assign parsed results in the caller's workspace.
names = fieldnames(parser.Results);
for nn = 1:numel(names)
    name = names{nn};
    value = parser.Results.(name);
    if ischar(target)
        assignin(target, name, value);
    elseif isstruct(target) || isprop(target, name)
        target.(name) = value;
    end
end
