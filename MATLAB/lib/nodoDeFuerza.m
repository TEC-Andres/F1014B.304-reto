%% nodoDeFuerza.m
% Modelaje del modelo
% F_w = mg
classdef nodoDeFuerza < superficies

	properties (Access = private)
		g = 9.81
		playbackStartZ = 0
		playbackImpactTime = 0
		playbackZFunc = []
		playbackDuration = 0
		playbackSteps = 0
		isPlaying = false
	end

	methods
		function obj = nodoDeFuerza()
			obj = obj@superficies();
			obj.plotLoop();
			obj.TimeSlider.ValueChangingFcn = @(src, event) obj.onSliderChanging(src, event);
			obj.TimeSlider.ValueChangedFcn = @(src, event) obj.onSliderChanged(src, event);
		end

		function bindRunButton(obj, callback)
			obj.Button.ButtonPushedFcn = @(~, ~) callback();
		end

		function runFallEngine(obj, startZ, dt)
			if nargin < 2 || isempty(startZ)
				startZ = obj.cylinder.z0;
			end
			if nargin < 3 || isempty(dt)
				dt = 0.05; % Tamaño de paso por segundo default
			end
			validateattributes(startZ, {'numeric'}, {'scalar','nonnegative'});
			validateattributes(dt, {'numeric'}, {'scalar','positive'});

			obj.playbackStartZ = startZ;
			obj.playbackImpactTime = sqrt(2 * startZ / obj.g);

			% Store playback function and params so slider can seek
			obj.playbackZFunc = @(t) max(0, obj.playbackStartZ - 0.5 * obj.g * (t.^2));
			obj.playbackDuration = obj.playbackImpactTime;
			obj.playbackSteps = max(2, floor(obj.playbackDuration / dt) + 1);

			obj.TimeSlider.Value = 0;
			obj.TimeSlider.Limits = [0 obj.playbackDuration];
			obj.Button.Enable = 'off';
			obj.isPlaying = true;
			try
				t = linspace(0, obj.playbackDuration, obj.playbackSteps);
				for k = 1:obj.playbackSteps
					z0 = obj.playbackZFunc(t(k));
					obj.setCylinderPose(z0);
					obj.plotLoop();
					obj.TimeSlider.Value = t(k);
					drawnow;
					pause(dt);
				end
			catch ME
				obj.Button.Enable = 'on';
				obj.isPlaying = false;
				rethrow(ME);
			end
			obj.isPlaying = false;
			obj.Button.Enable = 'on';
		end
	end

	methods (Access = private)
		function onSliderChanging(obj, ~, event)
			% live drag: update scene to correspond to current slider value
			val = event.Value;
			obj.expandTimelineIfNeeded(val);
			% Use fast (low-res) updates while dragging for responsiveness
			obj.updateFromTime(val, true);
		end

		function onSliderChanged(obj, src, ~)
			% release/click: update scene
			val = src.Value;
			obj.expandTimelineIfNeeded(val);
			% Use full resolution when finished
			obj.updateFromTime(val, false);
		end

		function updateFromTime(obj, tVal, fast)
			if nargin < 3
				fast = false;
			end
			if isempty(obj.playbackZFunc)
				return
			end
			% clamp for physics window
			tClamped = max(0, min(obj.playbackImpactTime, tVal));
			z0 = obj.playbackZFunc(tClamped);
			obj.setCylinderPose(z0);
			obj.plotLoop(fast);
		end

		function expandTimelineIfNeeded(obj, tVal)
			if tVal < 0
				return
			end
			currentMax = obj.TimeSlider.Limits(2);
			if tVal >= currentMax
				newMax = currentMax + max(0.5, 0.25 * currentMax);
				obj.playbackDuration = newMax;
				obj.TimeSlider.Limits = [0 newMax];
			end
		end
	end
end