classdef SsInputParser < inputParser
    % Make argument parsing and assignment of values into one-liner.
    %
    % The idea here is that I like the Matlab inputParser class, but using
    % it requires A lot of redundant typing.  The worst part is taking
    % values out of the parser's Results field and assigning them in the
    % relevant workspace or object.  Since the variable names and values
    % are all known to the parser already, it should be able to do this
    % work for us.  That's what this class does.
    %
    % Here's an example of code for a calling function:
    %
    %   parser = inputParser();
    %   parser.addRequired('name', @ischar);
    %   parser.addParameter('height', 1.8, @isnumeric);
    %   ssParseMagically(parser, 'caller', name, varargin{:});
    %   disp(height);
    %
    % 2016 isetbio team
    
    methods
        function obj = SsInputParser()
            obj.KeepUnmatched = true;
            obj.CaseSensitive = true;
            obj.PartialMatching = false;
        end
        
        function target = parseMagically(obj, target, varargin)
            % target = parser.ssParseMagically(target, varargin) invokes
            % Uses this parser to parse the given varargin.  Then for each
            % parser Results field, assigns the named value to the given
            % target.
            %
            % If the target is a struct or object, assigns to fields of
            % target and returns the updated struct or object.  If the
            % target is a string, uses Matlab's magical assignin() function
            % to assign the named value in the target workspace ('caller'
            % or 'base').
            
            % parse normally
            obj.parse(varargin{:});
            
            % assign results to target
            %   which might use assignin() magic
            names = fieldnames(obj.Results);
            for nn = 1:numel(names)
                name = names{nn};
                value = obj.Results.(name);
                if ischar(target)
                    assignin(target, name, value);
                elseif isstruct(target) || isprop(target, name)
                    target.(name) = value;
                end
            end
            
        end
    end
end