--Start of Global Scope---------------------------------------------------------

print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 1000 -- ms between visualization steps for demonstration purpose

-- Creating viewer
local viewer = View.create()

-- Setting up graphical overlay attributes
local contourDeco = View.ShapeDecoration.create()
contourDeco:setLineColor(0, 219, 0):setLineWidth(3.0)

local regionDec = View.PixelRegionDecoration.create():setColor(0, 0, 255, 50)
local shapeDec = View.ShapeDecoration.create():setLineColor(0, 100, 255, 255)
shapeDec:setLineWidth(5.0):setPointSize(5)

local textDec = View.TextDecoration.create():setColor(0, 255, 0)
textDec:setSize(40):setPosition(10, 140)

-- Load images
local images = {}
for ii = 1, 6 do
  images[ii] = Image.load('resources/' .. tostring(ii - 1) .. '.png'):toGray()
end

local teachIm = images[1]

-- Set a teach region
local teachRegionPositive1 = Image.PixelRegion.createRectangle(695, 347, 878, 520)
local teachRegionPositive2 = Image.PixelRegion.createRectangle(695, 735, 878, 930)
local teachRegionNegative = Image.PixelRegion.createRectangle(735, 416, 829, 852)
local teachRegion = teachRegionPositive1:getUnion(teachRegionPositive2):getDifference(teachRegionNegative)

-- Create and parameterize the edge matcher
local matcher = Image.Matching.EdgeMatcher.create()
-- The edge threshold is important to get correct inspect object model generated (see below)
matcher:setEdgeThreshold(60)
matcher:setRotationRange(math.pi / 8)
-- Use clutter level MEDIUM first
matcher:setBackgroundClutter('MEDIUM')
-- As the object in this example is relatively small only slight downsampling is possible
local wantedDownsampleFactor = 4.0
local wantedDownsampleFactorLess = 9.0

-- Find at most 1 object
matcher:setMaxMatches(1)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

---Performs a match operation on all images
---@param dsf int
local function match(dsf)
  -- Check if wanted downsample factor is supported by device
  local minDsf,_ = matcher:getDownsampleFactorLimits(teachIm)
  if (minDsf > dsf) then
    print("Cannot use downsample factor " .. dsf .. " will use " .. minDsf .. " instead")
    dsf = minDsf
  end
  matcher:setDownsampleFactor(dsf)

  -- Teach the matcher
  local teachPose = matcher:teach(teachIm, teachRegion)
  local modelContours = matcher:getModelContours()
  local modelPoints = matcher:getModelPoints()

  -- Show teach image
  viewer:clear()
  viewer:addImage(teachIm)
  viewer:addPixelRegion(teachRegion, regionDec)
  viewer:addShape(Shape.transform(matcher:getModelContours(), teachPose), shapeDec)
  viewer:addText('Teach image ', textDec)
  viewer:present()
  Script.sleep(DELAY * 2) -- for demonstration purpose only

  -- Do matching
  local totalTime = 0
  for ii = 1, 6 do
    local transforms, _ = matcher:match(images[ii])
    local matchTime = matcher:getMatchTime()
    totalTime = totalTime + matchTime

    -- Present match
    viewer:clear()
    viewer:addImage(images[ii])
    viewer:addShape(Point.transform(modelPoints, transforms[1]), shapeDec)
    viewer:addShape(Shape.transform(modelContours, transforms[1]), shapeDec)
    viewer:addText(
      'Clutter level: ' .. matcher:getBackgroundClutter() .. '\nImage: ' ..
      tostring(ii) .. '\nTime: ' .. tostring(matchTime), textDec
    )
    viewer:present()
    Script.sleep(DELAY) -- for demonstration purpose only
  end

  print('Total match time: ' .. tostring(totalTime))
end

local function main()
  -- Do matching
  match(wantedDownsampleFactor)
  -- Switch to clutter level MEDIUM and re-run
  matcher:setBackgroundClutter('HIGH')
  -- Using less downsampling
  -- Do matching
  match(wantedDownsampleFactorLess)
  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
