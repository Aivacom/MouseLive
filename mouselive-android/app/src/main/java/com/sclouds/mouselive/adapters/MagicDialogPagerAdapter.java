package com.sclouds.mouselive.adapters;

import android.content.Context;

import com.sclouds.mouselive.R;
import com.sclouds.mouselive.views.EffectBeautyFragmrnt;
import com.sclouds.mouselive.views.EffectStickerFragmrnt;
import com.sclouds.mouselive.views.EffectFilterFragmrnt;
import com.sclouds.mouselive.views.EffectGestureFragmrnt;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

/**
 * 魔术菜单
 *
 * @author Aslan chenhengfei@yy.com
 * @date 2020/04/24
 */
public class MagicDialogPagerAdapter extends FragmentPagerAdapter {
    private String[] titles;

    public MagicDialogPagerAdapter(Context context, @NonNull FragmentManager fm) {
        super(fm);
        titles = context.getResources().getStringArray(R.array.magic_dialog_title);
    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        if (position == 0) {
            return EffectBeautyFragmrnt.newInstance();
        } else if (position == 1) {
            return EffectFilterFragmrnt.newInstance();
        } else if (position == 2) {
            return EffectStickerFragmrnt.newInstance();
        } else {
            return EffectGestureFragmrnt.newInstance();
        }
    }

    @Override
    public int getCount() {
        return titles.length;
    }

    @Nullable
    @Override
    public CharSequence getPageTitle(int position) {
        return titles[position];
    }
}
