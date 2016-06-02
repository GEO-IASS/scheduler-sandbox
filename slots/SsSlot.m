classdef SsSlot < handle
    % Describe a required object, and where to assign it.
    
    properties
        assignmentTarget;
        invocationTarget;
        requiredClass;
        requiredProperties;
        preferredProperties;
        isTakeAll = false;
        isAutocreate = false;
    end
    
    methods
        function obj = assignAs(obj, assignmentTarget)
            parser = SsInputParser();
            parser.addRequired('assignmentTarget', @ischar);
            parser.parseMagically(obj, assignmentTarget);
        end
        
        function obj = passTo(obj, invocationTarget)
            parser = SsInputParser();
            parser.addRequired('invocationTarget', @ischar);
            parser.parseMagically(obj, invocationTarget);
        end
        
        function obj = requireClass(obj, requiredClass)
            parser = SsInputParser();
            parser.addRequired('requiredClass', @ischar);
            parser.parseMagically(obj, requiredClass);
        end
        
        function obj = requireProperty(obj, name, varargin)
            parser = SsInputParser();
            parser.addRequired('name', @ischar);
            parser.addParameter('value', []);
            parser.addParameter('validator', [], @(v) isempty(v) || isa(v, 'function_handle'));
            requirement = parser.parseMagically(struct(), name, varargin{:});
            
            if isempty(obj.requiredProperties)
                obj.requiredProperties = requirement;
            else
                obj.requiredProperties(end+1) = requirement;
            end
        end
        
        function obj = preferProperty(obj, name, varargin)
            parser = SsInputParser();
            parser.addRequired('name', @ischar);
            parser.addParameter('value', []);
            parser.addParameter('validator', [], @(v) isempty(v) || isa(v, 'function_handle'));
            preference = parser.parseMagically(struct(), name, varargin{:});
            
            if isempty(obj.preferredProperties)
                obj.preferredProperties = preference;
            else
                obj.preferredProperties(end+1) = preference;
            end
        end
        
        function obj = autocreate(obj, isAutocreate)
            parser = SsInputParser();
            parser.addRequired('isAutocreate', @islogical);
            parser.parseMagically(obj, isAutocreate);
        end
        
        function obj = takeAll(obj, isTakeAll)
            parser = SsInputParser();
            parser.addRequired('isTakeAll', @islogical);
            parser.parseMagically(obj, isTakeAll);
        end
        
        function [score, message] = evaluateOffering(obj, offering)
            % Compare offering to requirements and preferences for a score:
            %   - not required class -> score = 0
            %   - failed to match any required property -> score = 0
            %   - pass class and property requirements -> score = 1
            %   - succeed to match each preferred property -> score++
            
            score = 0;
            
            % not required class -> score = 0
            if ~isa(offering, obj.requiredClass)
                message = sprintf('Offering has class "%s" but should be "%s".', ...
                    class(offering), obj.requiredClass);
                return;
            end
            
            % failed to match any required property -> score = 0
            nRequirements = numel(obj.requiredProperties);
            for rr = 1:nRequirements
                requirement = obj.requiredProperties(rr);
                [isMatched, message] = obj.matchProperty(requirement, offering);
                if ~isMatched
                    return;
                end
            end
            
            score = 1;
            
            % succeed to match each preferred property -> score++
            nPreferences = numel(obj.preferredProperties);
            for pp = 1:nPreferences
                preference = obj.preferredProperties(pp);
                isMatched = obj.matchProperty(preference, offering);
                if isMatched
                    score = score + 1;
                end
            end
            
            message = sprintf('Object matched with %d preferences and score %d', ...
                nPreferences, score);
        end
        
        function [isMatched, message] = matchProperty(obj, matchingInfo, offering)
            isMatched = false;
            
            % offering must have a property with the given name
            if ~isprop(offering, matchingInfo.name) ...
                    && ~isfield(offering, matchingInfo.name)
                message = sprintf('Offering lacks required property "%s".', ...
                    matchingInfo.name);
                return;
            end
            
            % compare named property to a given value
            propValue = offering.(matchingInfo.name);
            expectedValue = matchingInfo.value;
            if ~isempty(expectedValue) && ~isequal(expectedValue, propValue)
                message = sprintf('Property "%s" value "%s" does not equal expected value "%s".', ...
                    matchingInfo.name, evalc('disp(propValue)'), evalc('disp(expectedValue)'));
                return;
            end
            
            % pass named property to a validation function
            validator = matchingInfo.validator;
            if ~isempty(validator) && ~feval(validator, propValue)
                message = sprintf('Property "%s" failed validator "%s".', ...
                    matchingInfo.name, func2str(validator));
                return;
            end
            
            % passed
            message = sprintf('Property "%s" matched OK.', matchingInfo.name);
            isMatched = true;
        end
    end
end
