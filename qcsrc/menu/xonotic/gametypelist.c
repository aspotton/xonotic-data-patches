#ifdef INTERFACE
CLASS(XonoticGametypeList) EXTENDS(XonoticListBox)
	METHOD(XonoticGametypeList, configureXonoticGametypeList, void(entity))
	ATTRIB(XonoticGametypeList, rowsPerItem, float, 1)
	METHOD(XonoticGametypeList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticGametypeList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticGametypeList, setSelected, void(entity, float))
	METHOD(XonoticGametypeList, loadCvars, void(entity))
	METHOD(XonoticGametypeList, saveCvars, void(entity))

	ATTRIB(XonoticGametypeList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticGametypeList, realUpperMargin, float, 0)
	ATTRIB(XonoticGametypeList, columnNameOrigin, float, 0)
	ATTRIB(XonoticGametypeList, columnNameSize, float, 0)
ENDCLASS(XonoticGametypeList)
entity makeXonoticGametypeList();
#endif

#ifdef IMPLEMENTATION

entity makeXonoticGametypeList(void)
{
	entity me;
	me = spawnXonoticGametypeList();
	me.configureXonoticGametypeList(me);
	return me;
}
void XonoticGametypeList_configureXonoticGametypeList(entity me)
{
	me.loadCvars(me);
	me.configureXonoticListBox(me);
	me.nItems = GameType_GetCount();
}
void XonoticGametypeList_setSelected(entity me, float i)
{
	SUPER(XonoticGametypeList).setSelected(me, i);
	me.saveCvars(me);
}

void XonoticGametypeList_loadCvars(entity me)
{
	float t;
	t = MapInfo_CurrentGametype();
	float i;
	for(i = 0; i < GameType_GetCount(); ++i)
		if(t == GameType_GetID(i))
			break;
	if(i >= GameType_GetCount())
	{
		for(i = 0; i < GameType_GetCount(); ++i)
			if(t == MAPINFO_TYPE_DEATHMATCH)
				break;
		if(i >= GameType_GetCount())
			i = 0;
	}
	me.setSelected(me, i);
	// do we need this: me.parent.gameTypeChangeNotify(me.parent); // to make sure
}
void XonoticGametypeList_saveCvars(entity me)
{
	float t;
	t = GameType_GetID(me.selectedItem);
	if(t == MapInfo_CurrentGametype())
		return;
	MapInfo_SwitchGameType(t);
	me.parent.gameTypeChangeNotify(me.parent);
}
void XonoticGametypeList_drawListBoxItem(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	s = GameType_GetName(i);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize)) * 0.5) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}
void XonoticGametypeList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticServerList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
	me.columnNameOrigin = 0;
	me.columnNameSize = 1;
}
#endif
