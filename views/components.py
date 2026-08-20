import customtkinter as ctk
from PIL import ImageTk
from config import (
    COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_PRIMARY, COLOR_PRIMARY_HOVER,
    COLOR_ACCENT, COLOR_ACCENT_HOVER, COLOR_LIGHT_BLUE, COLOR_TEXT_PRIMARY,
    COLOR_TEXT_SECONDARY, COLOR_TEXT_MUTED, COLOR_BORDER, COLOR_SUCCESS,
    COLOR_WARNING, COLOR_DANGER, COLOR_PURPLE, COMPANY_NAME, COMPANY_SLOGAN
)
from utils.assets import generate_tree_of_life_image

class HeaderFrame(ctk.CTkFrame):
    """ Header Superior Corporativo Rediseñado (Twinkle Bronze Style) """
    def __init__(self, master, title="PANEL DE CONTROL GENERAL", **kwargs):
        super().__init__(master, fg_color=COLOR_BG_CARD, corner_radius=0, height=72, **kwargs)
        self.pack_propagate(False)

        left_box = ctk.CTkFrame(self, fg_color="transparent")
        left_box.pack(side="left", padx=24, pady=10)

        # Logo Árbol de la Vida en contenedor elevado
        logo_box = ctk.CTkFrame(
            left_box, fg_color=("#E8EEF2", "#1C2230"),
            corner_radius=10, border_width=1, border_color=COLOR_BORDER
        )
        logo_box.pack(side="left", padx=(0, 14))

        pil_img = generate_tree_of_life_image(42, 42)
        self.logo_img = ctk.CTkImage(light_image=pil_img, dark_image=pil_img, size=(42, 42))

        logo_lbl = ctk.CTkLabel(logo_box, image=self.logo_img, text="")
        logo_lbl.pack(padx=6, pady=4)

        title_box = ctk.CTkFrame(left_box, fg_color="transparent")
        title_box.pack(side="left")

        comp_lbl = ctk.CTkLabel(
            title_box, text=COMPANY_NAME.upper(),
            font=ctk.CTkFont(family="Segoe UI", size=18, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        comp_lbl.pack(anchor="w")

        sub_lbl = ctk.CTkLabel(
            title_box, text=COMPANY_SLOGAN,
            font=ctk.CTkFont(family="Segoe UI", size=11),
            text_color=COLOR_TEXT_SECONDARY
        )
        sub_lbl.pack(anchor="w")

        # Contenedor derecho: Módulo actual e Indicador de usuario activo
        right_box = ctk.CTkFrame(self, fg_color="transparent")
        right_box.pack(side="right", padx=24, pady=10)

        self.mod_title_lbl = ctk.CTkLabel(
            right_box, text=title,
            font=ctk.CTkFont(family="Segoe UI", size=13, weight="bold"),
            text_color=COLOR_PRIMARY
        )
        self.mod_title_lbl.pack(anchor="e")

        self.user_lbl = ctk.CTkLabel(
            right_box, text="👤 Usuario: Invitado | Rol: Administrador",
            font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"),
            text_color=COLOR_TEXT_SECONDARY
        )
        self.user_lbl.pack(anchor="e", pady=(2, 0))

    def update_module_title(self, new_title):
        self.mod_title_lbl.configure(text=new_title)

    def set_user_info(self, nombre_completo, rol):
        self.user_lbl.configure(text=f"👤 {nombre_completo}  |  Rol: {rol}")


class StatusChip(ctk.CTkLabel):
    """ Badge / Tag de Estado Estilizado tipo Chip Twinkle """
    def __init__(self, master, text, status_type="success", **kwargs):
        color_map = {
            "success": (COLOR_SUCCESS, ("#D1FAE5", "#064E3B")),
            "warning": (COLOR_WARNING, ("#FEF3C7", "#451A03")),
            "danger": (COLOR_DANGER, ("#FEE2E2", "#451212")),
            "accent": (COLOR_PRIMARY, ("#FDF8F3", "#1C2230")),
            "purple": (COLOR_PURPLE, ("#F3E8FF", "#2E1065")),
            "muted": (COLOR_TEXT_MUTED, ("#E2E8F0", "#1E293B"))
        }
        fg_text, bg_fill = color_map.get(status_type, (COLOR_PRIMARY, ("#FDF8F3", "#1C2230")))
        super().__init__(
            master, text=text,
            font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"),
            text_color=fg_text, fg_color=bg_fill,
            corner_radius=6, padx=10, pady=4, **kwargs
        )


class MetricCard(ctk.CTkFrame):
    """ Tarjeta de Métrica KPI Twinkle Bronze con Tendencia e Ícono """
    def __init__(self, master, title, value, icon="📊", subtext="", trend="▲ +12.5%", accent_color=COLOR_PRIMARY, **kwargs):
        super().__init__(
            master, fg_color=COLOR_BG_CARD, corner_radius=14,
            border_width=1, border_color=COLOR_BORDER, **kwargs
        )

        padding_frame = ctk.CTkFrame(self, fg_color="transparent")
        padding_frame.pack(fill="both", expand=True, padx=18, pady=16)

        top_row = ctk.CTkFrame(padding_frame, fg_color="transparent")
        top_row.pack(fill="x")

        lbl_title = ctk.CTkLabel(
            top_row, text=title.upper(),
            font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"),
            text_color=COLOR_TEXT_MUTED
        )
        lbl_title.pack(side="left")

        # Ícono en caja estilizada
        icon_box = ctk.CTkFrame(
            top_row, fg_color=("#F0F4F7", "#1C2230"),
            corner_radius=8, width=34, height=34
        )
        icon_box.pack(side="right")
        icon_box.pack_propagate(False)

        lbl_icon = ctk.CTkLabel(
            icon_box, text=icon,
            font=ctk.CTkFont(size=16), text_color=accent_color
        )
        lbl_icon.pack(expand=True)

        self.lbl_value = ctk.CTkLabel(
            padding_frame, text=value,
            font=ctk.CTkFont(family="Segoe UI", size=26, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        self.lbl_value.pack(anchor="w", pady=(8, 4))

        bot_row = ctk.CTkFrame(padding_frame, fg_color="transparent")
        bot_row.pack(fill="x")

        if trend:
            trend_badge = ctk.CTkLabel(
                bot_row, text=trend,
                font=ctk.CTkFont(family="Segoe UI", size=10, weight="bold"),
                text_color=COLOR_SUCCESS if "▲" in trend else (COLOR_DANGER if "▼" in trend else COLOR_PRIMARY),
                fg_color=("#E2E8F0", "#1C2230"), corner_radius=4, padx=6, pady=2
            )
            trend_badge.pack(side="left", padx=(0, 8))

        if subtext:
            lbl_sub = ctk.CTkLabel(
                bot_row, text=subtext,
                font=ctk.CTkFont(family="Segoe UI", size=11),
                text_color=COLOR_TEXT_MUTED
            )
            lbl_sub.pack(side="left")

    def set_value(self, new_val):
        self.lbl_value.configure(text=new_val)


class PrimaryButton(ctk.CTkButton):
    """ Botón Principal Estilizado (Warm Bronze) """
    def __init__(self, master, text, command=None, icon=None, **kwargs):
        full_text = f"{icon} {text}" if icon else text
        btn_height = kwargs.pop("height", 38)
        super().__init__(
            master, text=full_text, command=command,
            fg_color=COLOR_PRIMARY, hover_color=COLOR_PRIMARY_HOVER,
            text_color="#FFFFFF", corner_radius=8,
            font=ctk.CTkFont(family="Segoe UI", size=12, weight="bold"),
            height=btn_height, **kwargs
        )


class AccentButton(ctk.CTkButton):
    """ Botón Secundario Estilizado (Steel Slate) """
    def __init__(self, master, text, command=None, icon=None, **kwargs):
        full_text = f"{icon} {text}" if icon else text
        btn_height = kwargs.pop("height", 38)
        super().__init__(
            master, text=full_text, command=command,
            fg_color=("#E2E8EC", "#3F4A5C"), hover_color=("#CBD5E0", "#323B4A"),
            text_color=COLOR_TEXT_PRIMARY, border_width=1, border_color=COLOR_BORDER, corner_radius=8,
            font=ctk.CTkFont(family="Segoe UI", size=12, weight="bold"),
            height=btn_height, **kwargs
        )


class CardFrame(ctk.CTkFrame):
    """ Contenedor Tarjeta Reutilizable Estilo Twinkle """
    def __init__(self, master, **kwargs):
        super().__init__(
            master, fg_color=COLOR_BG_CARD,
            corner_radius=12, border_width=1, border_color=COLOR_BORDER,
            **kwargs
        )
