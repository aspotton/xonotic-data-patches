#ifdef INTERFACE
CLASS(XonoticInputBox) EXTENDS(InputBox)
	METHOD(XonoticInputBox, configureXonoticInputBox, void(entity, float, string))
	METHOD(XonoticInputBox, focusLeave, void(entity))
	METHOD(XonoticInputBox, setText, void(entity, string))
	ATTRIB(XonoticInputBox, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticInputBox, image, string, SKINGFX_INPUTBOX)
	ATTRIB(XonoticInputBox, onChange, void(entity, entity), SUB_Null)
	ATTRIB(XonoticInputBox, onChangeEntity, entity, NULL)
	ATTRIB(XonoticInputBox, onEnter, void(entity, entity), SUB_Null)
	ATTRIB(XonoticInputBox, onEnterEntity, entity, NULL)
	ATTRIB(XonoticInputBox, marginLeft, float, SKINMARGIN_INPUTBOX_CHARS)
	ATTRIB(XonoticInputBox, marginRight, float, SKINMARGIN_INPUTBOX_CHARS)
	ATTRIB(XonoticInputBox, color, vector, SKINCOLOR_INPUTBOX_N)
	ATTRIB(XonoticInputBox, colorF, vector, SKINCOLOR_INPUTBOX_F)

	ATTRIB(XonoticInputBox, alpha, float, SKINALPHA_TEXT)

	ATTRIB(XonoticInputBox, cvarName, string, string_null)
	METHOD(XonoticInputBox, loadCvars, void(entity))
	METHOD(XonoticInputBox, saveCvars, void(entity))
	METHOD(XonoticInputBox, keyDown, float(entity, float, float, float))

	ATTRIB(XonoticInputBox, saveImmediately, float, 0)
ENDCLASS(XonoticInputBox)
entity makeXonoticInputBox(float, string);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticInputBox(float doEditColorCodes, string theCvar)
{
	entity me;
	me = spawnXonoticInputBox();
	me.configureXonoticInputBox(me, doEditColorCodes, theCvar);
	return me;
}
void XonoticInputBox_configureXonoticInputBox(entity me, float doEditColorCodes, string theCvar)
{
	me.configureInputBox(me, "", 0, me.fontSize, me.image);
	me.editColorCodes = doEditColorCodes;
	if(theCvar)
	{
		me.cvarName = theCvar;
		me.tooltip = getZonedTooltipForIdentifier(theCvar);
		me.loadCvars(me);
	}
	me.cursorPos = strlen(me.text);
}
void XonoticInputBox_focusLeave(entity me)
{
	me.saveCvars(me);
}
void XonoticInputBox_setText(entity me, string new)
{
	if(me.text != new)
	{
		SUPER(XonoticInputBox).setText(me, new);
		me.onChange(me, me.onChangeEntity);
		if(me.saveImmediately)
			me.saveCvars(me);
	}
	else
		SUPER(XonoticInputBox).setText(me, new);
}
void XonoticInputBox_loadCvars(entity me)
{
	if not(me.cvarName)
		return;
	SUPER(XonoticInputBox).setText(me, cvar_string(me.cvarName));
}
void XonoticInputBox_saveCvars(entity me)
{
	if not(me.cvarName)
		return;
	cvar_set(me.cvarName, me.text);
}
float XonoticInputBox_keyDown(entity me, float key, float ascii, float shift)
{
	float r;
	r = 0;
	if(key == K_ENTER || key == K_KP_ENTER)
	{
		if(me.cvarName)
		{
			me.saveCvars(me);
			r = 1;
		}
		me.onEnter(me, me.onEnterEntity);
	}
	if(SUPER(XonoticInputBox).keyDown(me, key, ascii, shift))
		r = 1;
	return r;
}
#endif
