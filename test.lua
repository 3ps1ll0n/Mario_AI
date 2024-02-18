NOM_STATE = "debut.state"

console.log('Hello World')
savestate.load(NOM_STATE)
while true do
    local mario = memory.read_s16_le(0x94);
    --memory.writebyte(0x19, 1);
    gui.text(50, 50, mario);
    joypad.set({Right=true, B=true, Y=true}, 1)
    emu.frameadvance()

    if memory.readbyte(0x13E0) == 62 then
        savestate.load(NOM_STATE)
    end
end