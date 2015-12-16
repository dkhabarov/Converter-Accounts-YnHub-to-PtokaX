--[[ ::::::::::::::::::::::::::::: Copyright (с) 2010 by Saymon :::::::::::::::::::::::::::::::
*		Описание скрипта: Конвертер аккаунтов из YnHub в PtokaX. 
							Для запуска конвертера нужно набрать в чат +reg_converter или альтернатива +запустить_рег_конвертер
							Будьте внимательны с  настройкой таблицы ProfileReg!!!
--
Данный скрипт был написан специально для DC.Etherway.Ru.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::: Настройки скрипта ::::::::::::::::::::::::::::::::::::::]]
YnHubSettingsPath = "D:\\Direct Connect\\DC Server\\testing_hubs\\YnHub_1.036.152\\settings\\" -- Полный путь до папки settings, 
																								-- в которой расположен файл с аккаунтами.
AccountsFile = "accounts.xml" 	-- файл с аккаунтами
								-- Таблица профилей. 1 - Профили YnHub. 2 Профили PtokaX. БУДЬТЕ ВНИМАТЕЛЬНЫ В НАСТРОЙКЕ!!!
								-- Пример настройки таблицы: Допустим, На YnHub'e у Вас название профиля зарегистрированных юзеров 
								-- Registered, а в ProkaX - Reg, то тогда в этой таблице нужно написать  ["Registered"] = "Reg", 
								-- Профиль оператора назван как OP, а в PtokaX - Operator
								-- Соответственно нужно написать ["OP"] = "Operator",
ProfileReg = {
	["Owner"] = "Master",  
	["OP"] = "Operator", 
	["VIP"] = "VIP", 
	["Registered"] = "Reg", 
	["Reg"] = "Reg", 
} 
--::::::::::::::::::::: Далее основной код скрипта. Лучше НИЧЕГО НЕ ТРОГАТЬ!!! :::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function YnHubRegister(sFileName) 
    local curTable = {} 
    local curNick = "" 
    local Count = 0 
    local hFile,sE = io.open(sFileName, "r") 
	if hFile == nil then 
		Core.SendToAll("Converter",tostring(hFile).." : "..tostring(sE)) 
	end 
    for line in hFile:lines() do 
        local s,e,col,value = string.find(line, "<(%S+)>(%S+)<") 
        if col and value then 
            if col == "Nick" and Count == 0 then 
                curNick = value 
                curTable[value] = {["Pass"] = "", ["Profile"] = ""} 
                Count = Count + 1 
            elseif col == "Pass" and Count == 1 then 
                curTable[curNick].Pass = value 
                Count = Count + 1 
            elseif col == "Profile" and Count == 2 then 
                curTable[curNick].Profile = value 
                Count = 0 
            end 
        end 
    end 
    hFile:close() 
    return curTable 
end 
function ChatArrival(tUser,sData) 
	local _,_,Cmd = string.find(sData, "%b<>%s*(%S+)%|") 
	if Cmd == "+reg_converter" or Cmd == "+запустить_рег_конвертер" then 
		Core.SendToNick(tUser.sNick,"<AccountsConverter> *** Конвертация аккаунтов из YnHub в PtokaX запущена") 
		local T = YnHubRegister(YnHubSettingsPath..AccountsFile) 
		local ynhub_regs,on_px_regs,err_regs = 0,0,0 
		for nick,_ in pairs(T) do 
			ynhub_regs = ynhub_regs + 1 
			if ProfileReg[T[nick].Profile] and ProfMan.GetProfile(ProfileReg[T[nick].Profile]) ~= nil then 
				p = ProfMan.GetProfile(ProfileReg[T[nick].Profile]) 
				if p.iProfileNumber ~= -1 then 
					on_px_regs = on_px_regs + 1 
					RegMan.AddReg(nick,T[nick].Pass, p.iProfileNumber) 
				else 
					err_regs = err_regs + 1 
				end 
			else 
				err_regs = err_regs +1 
			end 
		end 
		Core.SendToNick(tUser.sNick,"<AccountsConverter> *** Всего ( "..ynhub_regs.." ) юзер (ов) зарегистрировано в базе регистраций YnHub ") 
		Core.SendToNick(tUser.sNick,"<AccountsConverter> *** Всего ( "..on_px_regs.." ) юзер (ов) зарегистрировано в PtokaX") 
		Core.SendToNick(tUser.sNick,"<AccountsConverter> *** Всего ( "..err_regs.." ) аккаунтов не перенесены, поскольку профили не существуют в PtokaX или возможно была допущена ошибка в таблице ProfileReg или в переменной YnHubSettingsPath") 
		return true 
	end 
end 
function OnError(LUA_err) 
	Core.SendToOps(LUA_err) 
end
