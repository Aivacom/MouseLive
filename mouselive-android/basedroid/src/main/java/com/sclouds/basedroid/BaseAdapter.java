package com.sclouds.basedroid;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.LayoutRes;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.Size;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 基础类
 *
 * @author chenhengfei@yy.com
 * @since 2020年2月20日
 */
public abstract class BaseAdapter<D, BVH extends BaseAdapter.BaseViewHolder<D>>
        extends RecyclerView.Adapter<BVH> {
    @Nullable
    protected List<D> mData;
    protected Context mContext;
    protected OnItemClickListener mItemClickListener;

    public interface OnItemClickListener {
        void onItemClick(@NonNull View view, @Size(min = 0) int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.mItemClickListener = listener;
    }

    public BaseAdapter(Context context) {
        this.mContext = context;
    }

    public BaseAdapter(Context context, @NonNull List<D> mData) {
        this.mContext = context;
        this.mData = mData;
    }

    @Override
    public int getItemCount() {
        return mData == null ? 0 : mData.size();
    }

    @Nullable
    public D getDataAtPosition(@Size(min = 0) int position) {
        if (mData == null) {
            return null;
        }

        if (position >= mData.size()) {
            return null;
        }
        return mData.get(position);
    }

    public void setData(@NonNull List<D> data) {
        this.mData = data;
        notifyDataSetChanged();
    }

    @LayoutRes
    protected abstract int getLayoutId(int viewType);

    protected abstract BVH createViewHolder(@NonNull View itemView);

    @NonNull
    @Override
    public BVH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View itemView =
                LayoutInflater.from(mContext).inflate(getLayoutId(viewType), parent, false);
        BVH mHolder = createViewHolder(itemView);
        mHolder.setItemClickListener(mItemClickListener);
        return mHolder;
    }

    @Override
    public void onBindViewHolder(@NonNull BVH holder, int position) {
        if (mData == null) {
            return;
        }
        holder.bind(mData.get(position));
    }

    /**
     * 添加数据 更新数据集不是用adapter.notifyDataSetChanged()而是notifyItemInserted(position)与notifyItemRemoved(position)
     * 否则没有动画效果
     */
    public void addItem(@NonNull D data) {
        if (mData == null) {
            mData = new ArrayList<>();
        }

        mData.add(data);
        notifyItemInserted(mData.size() - 1);
    }

    /**
     * 添加数据 更新数据集不是用adapter.notifyDataSetChanged()而是notifyItemInserted(position)与notifyItemRemoved(position)
     * 否则没有动画效果
     */
    public void addItem(@Size(min = 0) int postion, @NonNull D data) {
        if (mData == null) {
            mData = new ArrayList<>();
        }

        mData.add(postion, data);
        notifyItemInserted(postion);
    }

    /**
     * 删除
     */
    public void deleteItem(@Size(min = 0) int posion) {
        if (mData == null || mData.isEmpty()) {
            return;
        }

        if (0 <= posion && posion < mData.size()) {
            mData.remove(posion);
            notifyItemRemoved(posion);
        }
    }

    /**
     * 删除
     */
    public void deleteItem(@NonNull D data) {
        if (mData == null || mData.isEmpty()) {
            return;
        }

        int index = mData.indexOf(data);
        if (0 <= index && index < mData.size()) {
            mData.remove(data);
            notifyItemRemoved(index);
        }
    }

    public void clear() {
        if (mData == null || mData.isEmpty()) {
            return;
        }

        mData.clear();
        notifyDataSetChanged();
    }

    public static abstract class BaseViewHolder<D> extends RecyclerView.ViewHolder {
        protected Context mContext;
        protected OnItemClickListener mItemClickListener;

        public BaseViewHolder(@NonNull View itemView) {
            super(itemView);
            mContext = itemView.getContext();
            itemView.setOnClickListener((view) -> {
                if (mItemClickListener != null) {
                    mItemClickListener.onItemClick(view, getAdapterPosition());
                }
            });
        }

        public void setItemClickListener(OnItemClickListener itemClickListener) {
            mItemClickListener = itemClickListener;
        }

        protected abstract void bind(@NonNull D d);
    }
}
