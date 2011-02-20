module Kirk
  def self.sub_process?
    !!defined?(Kirk::SUB_PROCESS)
  end
end
