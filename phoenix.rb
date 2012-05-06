# -*- encoding: UTF-8 -*-

require 'mechanize'
require 'kconv'
require 'nkf'

class Phoenix 

  LOGIN_URL = "http://s.dartsjapan.jp/index.php?module=Support&action=LoginNew"
  @agent = nil

  def initialize(cardno, passwd)# {{{

    @cardno = cardno
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
    @agent.get(LOGIN_URL)
    @agent.page.form_with(:name => 'frm') { |f|
      f.field_with(:name => 'login_id').value = cardno
      f.field_with(:name => 'login_pw').value = passwd
    }.click_button 
    @agent.page.encoding = 'CP932'
    check()
  end# }}}

  def check# {{{
    raise AuthError, "課金登録してませんか？" if /有料会員登録/u =~ @agent.page.title.toutf8
    @agent.page.link_with(:href => /id=#{@cardno}/).click
  end # }}}

  def getCardname# {{{
    raise InternalError, "get cardname failed" unless cardname = @agent.page.at('span.PlayerName')
    cardname.inner_text
  end# }}}

  def getRating# {{{
    raise InternalError, "get rating failed" unless rating = @agent.page.at('table.row3>tr>td').inner_text.split("\t")[1].strip
    rating
  end# }}}

  def getHomeshop# {{{
    raise InternalError, "get homeshop failed" unless @agent.page.at('ul.mymenuSub>li>a').inner_text =~ /^ホームショップ：(.+)$/u
    $1
  end# }}}

  def getStats# {{{
    
    result = {}
    ppd = @agent.page.search('span.dataname')[3].parent.inner_text.split("\t")[1..2]
    result[:ppd_stats] = ppd[0].strip
    result[:ppd_minus] = ppd[1].split.empty? ? '+0.00' : ppd[1].strip

    mpr = @agent.page.search('span.dataname')[4].parent.inner_text.split("\t")[1..2]
    result[:mpr_stats] = mpr[0].strip
    result[:mpr_minus] = mpr[1].strip.empty? ? '+0.00' : mpr[1].strip

    return result
  end# }}}

  def getCardInfo# {{{
    return {:cardname => getCardname,
            :rating => getRating,
            :homeshop => getHomeshop}
  end# }}}

  def getAward# {{{
    raise NoneError, '本日のアワードは見つかりませんでした' unless link = @agent.page.link_with(:text => "本日のプレイデータ".toutf8)
    link.click
    @agent.page.encoding = 'CP932'

    awards = %w(LOW\ TON 
                HAT\ TRICK
                HIGH\ TON
                TON\ OUT
                THREE\ IN\ A\ BED
                WHITE\ HORSE
                TON\ 80
                PHOENIX\ EYE)

    results = {}
    @agent.page.search('span').each do |s|
      data = s.inner_text.split(':')
      if awards.include?(data[0]) and data[1].to_i > 0 then
        results[data[0]] = data[1]
      end
    end

    return results
  end# }}}

end


class AuthError < Exception; end
class NoneError < Exception; end
class MentenanceError < Exception; end
class InternalError < Exception; end
