package com.lightmind.webviewapp

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.kyant.backdrop.Backdrop
import com.kyant.backdrop.drawBackdrop
import com.kyant.backdrop.effects.blur
import com.kyant.backdrop.effects.lens
import com.kyant.backdrop.effects.vibrancy
import com.kyant.backdrop.highlight.Highlight
import com.kyant.backdrop.shadow.InnerShadow
import com.kyant.backdrop.shadow.Shadow

private val DefaultTabs = listOf("首页", "搜索", "收藏", "我的")

/**
 * 基于 AndroidLiquidGlass (Backdrop) 的液态玻璃底部导航栏。
 *
 * 整条导航栏以及选中指示器都通过 [Backdrop] 对底部 WebView 内容进行折射/模糊/镜面化，
 * 仅用于展示效果，没有具体页面跳转逻辑。
 */
@Composable
fun LiquidGlassBottomBar(
    backdrop: Backdrop,
    modifier: Modifier = Modifier,
) {
    val isLightTheme = !isSystemInDarkTheme()
    val accentColor = if (isLightTheme) Color(0xFF0088FF) else Color(0xFF0A84FF)
    val barSurface = if (isLightTheme) Color(0xFFFAFAFA) else Color(0xFF121212)
    val inactiveColor = if (isLightTheme) Color(0xFF8A8A8E) else Color(0xFF9A9A9E)

    var selected by remember { mutableIntStateOf(0) }

    BoxWithConstraints(
        modifier = modifier,
        contentAlignment = Alignment.BottomCenter,
    ) {
        val tabCount = DefaultTabs.size
        val barWidthDp = maxWidth
        val tabWidth = barWidthDp / tabCount
        val animatedSelected by animateDpAsState(
            targetValue = tabWidth * selected,
            animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessMedium),
            label = "pillOffset",
        )

        // 主体液态玻璃导航条
        Row(
            Modifier
                .fillMaxWidth()
                .height(64.dp)
                .drawBackdrop(
                    backdrop = backdrop,
                    shape = { androidx.compose.foundation.shape.CircleShape },
                    effects = {
                        vibrancy()
                        blur(8f.dp.toPx())
                        lens(24f.dp.toPx(), 24f.dp.toPx())
                    },
                    onDrawSurface = { drawRect(barSurface.copy(alpha = 0.4f)) },
                ),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            DefaultTabs.forEachIndexed { index, label ->
                LiquidTabContent(
                    label = label,
                    isSelected = index == selected,
                    accentColor = accentColor,
                    inactiveColor = inactiveColor,
                    onClick = { selected = index },
                    modifier = Modifier.weight(1f),
                )
            }
        }

        // 选中指示器：一块叠加在导航条上的液态玻璃“药丸”
        Box(
            Modifier
                .offset(x = animatedSelected)
                .width(tabWidth)
                .height(64.dp)
                .padding(4.dp)
                .drawBackdrop(
                    backdrop = backdrop,
                    shape = { androidx.compose.foundation.shape.CircleShape },
                    effects = {
                        lens(
                            refractionHeight = 10f.dp.toPx(),
                            refractionAmount = 14f.dp.toPx(),
                            chromaticAberration = true,
                        )
                    },
                    highlight = { Highlight.Default },
                    shadow = { Shadow() },
                    innerShadow = { InnerShadow(radius = 8.dp, alpha = 0.5f) },
                    onDrawSurface = {
                        drawRect(if (isLightTheme) Color.Black.copy(alpha = 0.04f) else Color.White.copy(alpha = 0.04f))
                    },
                ),
        )
    }
}

@Composable
private fun RowScope.LiquidTabContent(
    label: String,
    isSelected: Boolean,
    accentColor: Color,
    inactiveColor: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val tint = if (isSelected) accentColor else inactiveColor
    Column(
        modifier = modifier
            .fillMaxHeight()
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = label,
            color = tint,
            fontSize = 14.sp,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            maxLines = 1,
        )
    }
}
