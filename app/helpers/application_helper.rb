module ApplicationHelper
 class JSONWithIndifferentAccess
    def self.load(str)
      obj = HashWithIndifferentAccess.new(JSON.load(str))
      #...or simply: obj = JSON.load(str, nil, symbolize_names:true)
      obj.freeze #i also want it set all or nothing, not piecemeal; ymmv
      obj
    end
    def self.dump(obj)
      JSON.dump(obj)
    end
  end
end
