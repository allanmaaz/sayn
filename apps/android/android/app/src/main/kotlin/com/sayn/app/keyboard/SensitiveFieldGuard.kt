package com.sayn.app.keyboard

import android.text.InputType
import android.view.inputmethod.EditorInfo

object SensitiveFieldGuard {

    fun isSensitiveField(attribute: EditorInfo?): Boolean {
        if (attribute == null) return false

        val variation = attribute.inputType and InputType.TYPE_MASK_VARIATION
        val isPassword = variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD

        val isNumberPassword = attribute.inputType and InputType.TYPE_CLASS_NUMBER != 0 &&
                attribute.inputType and InputType.TYPE_NUMBER_VARIATION_PASSWORD != 0

        return isPassword || isNumberPassword
    }
}
