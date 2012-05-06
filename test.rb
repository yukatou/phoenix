# -*- encoding: UTF-8 -*-

require './phoenix'

cardno = "0255854426756610"
passwd = "0226"

pn = Phoenix.new(cardno, passwd)

pp pn.getCardInfo
pp pn.getStats
pp pn.getAward
