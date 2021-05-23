module TkComponent
  module Builder
    class Event
      attr_accessor :name
      attr_accessor :sender
      attr_accessor :button_index
      attr_accessor :key_code
      attr_accessor :key_string
      attr_accessor :mouse_x
      attr_accessor :mouse_y
      attr_accessor :root_mouse_x
      attr_accessor :root_mouse_y
      attr_accessor :mouse_wheel_delta
      attr_accessor :data

      EVENT_ATTRS = "%x %y %X %Y %b %D %A %k %d"

      def initialize(name, sender)
        @name = name.to_sym
        @sender = sender
      end

      def self.emit(name, source, data)
        Tk.event_generate(source, "<#{name}>", data: data)
      end

      def self.bind_command(name, sender, options, lambda)
        sender.native_item.command do
          event = self.new(name, sender)
          lambda.call(event)
        end
      end

      def self.bind_variable(name, sender, options, lambda)
        handler = proc do
          event = self.new(name, sender)
          lambda.call(event)
        end
        sender.tk_variable.trace('write', handler)
      end

      def self.bind_event(name, sender, options, lambda, pre_lambda = nil, post_lambda = nil)
        event_string = self.event_string_for(name, options)
        handler = proc do |x, y, rx, ry, bi, mw, ks, kc, data|
          event = self.new(name, sender)
          event.mouse_x = x
          event.mouse_y = y
          event.root_mouse_x = rx
          event.root_mouse_y = ry
          event.button_index = bi
          event.mouse_wheel_delta = mw
          event.key_string = ks
          event.key_code = kc
          event.data = data
          # The pre_lambda returns true if it wants to prevent the event from firing
          return if pre_lambda.present? && pre_lambda.call(event)
          lambda.call(event)
          post_lambda.call(event) if post_lambda.present?
        end
        sender.native_item.bind(event_string, handler, EVENT_ATTRS)
      end

      def data_object
        @data_object ||= begin
                           ObjectSpace._id2ref(self.data.to_i)
                         rescue
                           nil
                         end
      end

      private

      def self.event_string_for(name, options)
        event_name = self.resolve_event_alias(name).to_s.camelize
        event_prefix = ''
        if button = options[:button]
          event_prefix << "B#{button}"
        end
        event_name = event_prefix + '-' + event_name if event_prefix.present?
        event_name
      end

      EVENT_ALIASES = {
        mouse_drag: :motion,
        mouse_down: :button_press,
        mouse_up: :button_release,
        mouse_enter: :enter,
        mouse_leave: :leave
      }

      def self.resolve_event_alias(name)
        if (found = EVENT_ALIASES[name])
          name = found
        end
        name
      end
    end
  end
end
