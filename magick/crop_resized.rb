module Magick
  class Image
    def crop_resized(ncols, nrows, gravity=CenterGravity)
      copy.crop_resized!(ncols, nrows, gravity)
    end
    
    def crop_resized!(ncols, nrows, gravity=CenterGravity)
      if ncols != columns || nrows != rows
        scale = [ncols/columns.to_f, nrows/rows.to_f].max
        resize!(scale*(columns+0.5), scale*(rows+0.5))
      end
      crop!(gravity, ncols, nrows, true) if ncols != columns || nrows != rows
      self
    end
  end
end