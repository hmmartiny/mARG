import matplotlib.pyplot as plt
import seaborn as sns
import os
import numpy as np
import pandas as pd

class reporter:

    def __init__(self, metadata, fig_dir='figures'):

        self.df = metadata
        self.fig_dir=fig_dir
        os.makedirs(self.fig_dir, exist_ok=True)

    def _vline(self, ax, **kwargs):
        ax.vlines(
            ymin=ax.get_ylim()[0], ymax=ax.get_ylim()[1],
            **kwargs
        )

        ax.legend()
    
    def density(self, x=None, y=None, title='', xlabel='', ylabel='', figsize=(10,7), vline_args={}, fname=None):

        fig, ax = plt.subplots(1,1, figsize=figsize)
        sns.violinplot(
            data = self.df,
            x = x,
            y= y,
            ax=ax
        )

        if vline_args:
            self._vline(ax, **vline_args)

        ax.set_title(title)
        ax.set_xlabel(xlabel)
        ax.set_ylabel(ylabel)
        
        fig.tight_layout()

        if fname is not None:
            plt.savefig(os.path.join(self.fig_dir, fname))
        
        plt.close(fig)
        return fig

    def boxplot(self, x=None, y=None, title='', xlabel='', ylabel='', figsize=(10,7), fname=None):

        fig, ax = plt.subplots(1,1, figsize=figsize)
        sns.boxplot(
            data = self.df,
            x = x,
            y= y,
            ax=ax
        )

        ax.set_title(title)
        ax.set_xlabel(xlabel)
        ax.set_ylabel(ylabel)

        fig.tight_layout()

        if fname is not None:
            plt.savefig(os.path.join(self.fig_dir, fname))

        plt.close(fig)
        
        return fig

    def table(self, tab, fname=None, figsize=(10,7)):

        fig, ax = plt.subplots(1,1, figsize=figsize)

        ax.table(
            cellText = tab.values,
            rowLabels = tab.index,
            colLabels = tab.columns,
            cellLoc = 'right',
            rowLoc = 'center',
            loc='center'
        )

        plt.axis('off')

        fig.tight_layout()

        if fname is not None:
            plt.savefig(os.path.join(self.fig_dir, fname))

        plt.close(fig)
        return fig

    def _summarise(self, fname=None):

        d = {}

        # count run_accession
        d['n_runs'] = self.df.run_accession.nunique()
        
        #  1.0×10-12 
        d['bytes'] = self.df.fastq_bytes.sum()  
        d['terabytes'] = d['bytes'] * 10**(-12)

        # reads
        d['reads'] = self.df.read_count.sum()
        d['terareads'] = d['reads'] * 10**(-12)

        # bases
        d['bases'] = self.df.base_count.astype('int').sum()
        d['terabases'] = d['bases'] * 10**(-12)

        tab1 = pd.DataFrame.from_dict(d, orient='index')
        tab1.columns = ['Summary for all matched datasets']

        if fname is not None:
            tab1.to_csv(os.path.join(self.fig_dir, fname))

        return tab1

    def build(self, min_read_count=0):

        self.df['log10_read_count'] = np.log10(self.df['read_count'])
        
        self.df['fastq_bytes'] = self.df['fastq_bytes'].fillna(0).astype('str').apply(
            lambda x: sum([int(b) for b in x.split(';')])
        )   

        # stats
        tab = self._summarise(fname='table_stats.csv')
        self.table(tab=tab, fname='table_stats.png')


        # Overview of read counts
        self.boxplot(
            x="log10_read_count", 
            xlabel=r"$\log_{10}$(read count)",
            ylabel="Density",
            title="Distribution of raw reads per sample",
            fname='readcount_boxplot.png'
        )  

        self.boxplot(
            x="log10_read_count", 
            y='library_layout',
            xlabel=r"$\log_{10}$(read count)",
            ylabel="Density",
            title="Distribution of raw reads per sample",
            fname='readcount_layout_boxplot.png'
        )  

        self.density(
            x="log10_read_count", 
            xlabel=r"$\log_{10}$(read count)",
            ylabel="Density",
            title="Distribution of raw reads per sample",
            fname='readcount_densityplot.png'
        )   
        
        self.density(
            x="log10_read_count", 
            y='library_layout',
            xlabel=r"$\log_{10}$(read count)",
            ylabel="Density",
            title="Distribution of raw reads per sample",
            fname='readcount_layout_densityplot.png'
        )   
        

        if min_read_count > 0:
            self.density(
                x="log10_read_count", 
                xlabel=r"$\log_{10}$(read count)",
                ylabel="Density",
                title="Distribution of raw reads per sample",
                vline_args={'x': np.log10(min_read_count), 'color': 'red', 'linestyle': '--', 'label': f"{int(min_read_count)} reads"},
                fname='readcount_densityplot_filter.png'
            )   

        