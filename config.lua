EXTER = {}

QBCore = exports['qb-core']:GetCoreObject()


EXTER.Target = "qb-target"
EXTER.CrackIcon = "fas fa-recycle"
-- REWARD OPTIONS
EXTER.NormalCash = false -- if false it will use black money
EXTER.Cash = math.random(5000, 10000)
EXTER.NormalCashName = 'cash' -- change this if using custom name
EXTER.BlackMoneyName = 'black_money'

-- TIMES
EXTER.BrokeTime = math.random(25000, 45000)
EXTER.ProgressTime = 7000
EXTER.TextLength = 2000 -- 3d text leight

-- LOCALES
EXTER.TextCrack = "Crack ATM"
EXTER.TextPutToCar = "Putting Rope To Car"
EXTER.TextAttach = "Attaching Rope To Atm"
EXTER.TextTCrack = "Cracking ATM"
EXTER.Text = "Press E to attach atm | Press X to remove rope"
EXTER.TextGotCash = "You got "

-- ROPE ITEM
EXTER.RopeItemName = "rope"
EXTER.RopeItemCount = 1 -- how many ropes will be removed
EXTER.UseRopeNotify = "You used rope"
EXTER.DontHaveRope = "You dont have rope"